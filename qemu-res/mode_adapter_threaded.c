/*
 * Copyright (c) 2025 Nikita Proshkin
 * All rights reserved.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <pthread.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <sys/epoll.h>

#define UDP_PORT 1234
#define TS_PACKET_SIZE 188
#define TS_PACKETS_PER_UDP 7
#define UDP_PAYLOAD_SIZE (TS_PACKET_SIZE * TS_PACKETS_PER_UDP)
#define BUFFER_SIZE 1024
#define DVB_S2_CRC8_POLY 0xD5 // x^8 + x^7 + x^6 + x^4 + x^2 + 1
#define Kbch 7274

typedef struct
{
    uint8_t data[BUFFER_SIZE][UDP_PAYLOAD_SIZE];
    uint32_t lens[BUFFER_SIZE];
    int head, tail;
    pthread_mutex_t lock;
} RingBuffer;

RingBuffer ring_buffer = {.head = 0, .tail = 0, .lock = PTHREAD_MUTEX_INITIALIZER};
uint8_t *scrambler;
uint32_t bytes_in_ts = 0;
uint32_t bytes_in_bbframe = 0;
uint8_t ts_crc = 0;

uint32_t *realtimer;
uint32_t real_start = 0;
uint32_t bytes_to_transfer;

void enqueue(uint8_t *packet, int len)
{
    if ((ring_buffer.head + 1) % BUFFER_SIZE == ring_buffer.tail)
    {
        printf("Buffer is full. Lost packets!\n");
        return; // Drop packets
    }
    memcpy(ring_buffer.data[ring_buffer.head], packet, len);
    ring_buffer.lens[ring_buffer.head] = len;
    ring_buffer.head = (ring_buffer.head + 1) % BUFFER_SIZE;
}

void *udp_listener(void *arg)
{
    int sockfd = socket(AF_INET, SOCK_DGRAM, 0);
    if (sockfd < 0)
    {
        perror("Socket creation failed");
        exit(1);
    }

    int rcvbuf_size = 4 * 1024 * 1024;
    setsockopt(sockfd, SOL_SOCKET, SO_RCVBUF, &rcvbuf_size, sizeof(rcvbuf_size));

    struct sockaddr_in server_addr = {0};
    server_addr.sin_family = AF_INET;
    server_addr.sin_addr.s_addr = htonl(INADDR_ANY);
    server_addr.sin_port = htons(UDP_PORT);

    if (bind(sockfd, (struct sockaddr *)&server_addr, sizeof(server_addr)) < 0)
    {
        perror("Bind failed");
        exit(1);
    }

    struct epoll_event ev, events;
    int epfd = epoll_create1(0);
    ev.events = EPOLLIN;
    ev.data.fd = sockfd;
    epoll_ctl(epfd, EPOLL_CTL_ADD, sockfd, &ev);

    uint8_t packet[UDP_PAYLOAD_SIZE];
    while (1)
    {
        int n = epoll_wait(epfd, &events, 1, -1);
        if (n)
        {
            int len = recvfrom(sockfd, packet, UDP_PAYLOAD_SIZE, 0, NULL, NULL);
            if (len > 0)
                enqueue(packet, len);
        }
    }
    close(sockfd);
    return NULL;
}

uint8_t dvb_s2_crc8(uint8_t old_crc, uint8_t new_byte)
{
    uint8_t crc = old_crc ^ new_byte;

    for (int i = 0; i < 8; i++)
    {
        if (crc & 0x80)
        {
            crc = (crc << 1) ^ DVB_S2_CRC8_POLY;
        }
        else
        {
            crc <<= 1;
        }
    }

    return crc;
}

void send_bbheader()
{
    uint8_t bbheader[9] = {0xF0, 0x00, 0x05, 0xE0, 0xE3, 0x00, 0x47};

    uint16_t SYNCD = ((TS_PACKET_SIZE - bytes_in_ts) % TS_PACKET_SIZE) * 8;
    bbheader[7] = (SYNCD >> 8) & 0xFF;
    bbheader[8] = SYNCD & 0xFF;

    uint8_t crc = 0;
    for (int i = 0; i < 9; i++)
    {
        crc = dvb_s2_crc8(crc, bbheader[i]);
        *scrambler = bbheader[i];
    }
    *scrambler = crc;
}

void process_udp_payload(uint8_t *packet, int len)
{
    for (int i = 0; i < len; i++)
    {
        if (bytes_to_transfer != 0)
            bytes_to_transfer--;

        if (bytes_in_bbframe == 0)
        {
            send_bbheader();
            bytes_in_bbframe += 10;
        }

        if (bytes_in_ts == 0)
        {
            if (packet[i] != 0x47)
            {
                continue;
            }
            else
            {
                *scrambler = ts_crc;
                ts_crc = 0;
                bytes_in_ts++;
                bytes_in_bbframe = (bytes_in_bbframe + 1) % Kbch;
            }
        }
        else
        {
            *scrambler = packet[i];
            ts_crc = dvb_s2_crc8(ts_crc, packet[i]);
            bytes_in_ts = (bytes_in_ts + 1) % TS_PACKET_SIZE;
            bytes_in_bbframe = (bytes_in_bbframe + 1) % Kbch;
        }
    }
}

void *bbframes_generator(void *opaque)
{
    int fd = open("/dev/mem", O_RDWR | O_SYNC);
    scrambler = mmap(NULL, 4096, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0x40001000);

    realtimer = mmap(NULL, 4096, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0xf8007000);

    struct timespec delay = {0};
    delay.tv_nsec = 100 * 1000;

    while (bytes_to_transfer != 0)
    {
        if (ring_buffer.head == ring_buffer.tail)
        {
            nanosleep(&delay, NULL);
        }
        else
        {
            if (real_start == 0)
            {
                real_start = realtimer[130];
            }
            process_udp_payload(ring_buffer.data[ring_buffer.tail],
                                ring_buffer.lens[ring_buffer.tail]);
            ring_buffer.tail = (ring_buffer.tail + 1) % BUFFER_SIZE;
        }
    }

    uint32_t proc_time = (realtimer[130] - real_start) / 1000000;
    printf("process time: %ds\n", proc_time);

    exit(0);
    return NULL;
}

int main(int argc, char *argv[])
{
    pthread_t thr1, thr2;

    bytes_to_transfer = atoi(argv[1]);

    pthread_create(&thr1, NULL, udp_listener, NULL);
    pthread_create(&thr2, NULL, bbframes_generator, NULL);

    pthread_join(thr1, NULL);
    pthread_join(thr2, NULL);

    return 0;
}
