#include "ntp_client.h"
#include "lwip/udp.h"
#include "lwip/pbuf.h"
#include "lwip/sys.h"
#include <string.h>
#include <stddef.h>

#define NTP_PORT          123U
/* Seconds between 1900-01-01 (NTP epoch) and 1970-01-01 (Unix epoch): 70 years */
#define NTP_EPOCH_DELTA   2208988800UL

static bool     s_synced    = false;
static uint32_t s_unix_base = 0U;  /* Unix timestamp captured at s_sync_ms */
static uint32_t s_sync_ms   = 0U;  /* sys_now() value when sync was established */

/* Convert Unix timestamp to calendar fields (UTC). */
static void unix_to_datetime(uint32_t t,
    uint16_t *yr, uint8_t *mo, uint8_t *dy,
    uint8_t *hr, uint8_t *mn, uint8_t *sc)
{
    *sc = (uint8_t)(t % 60U); t /= 60U;
    *mn = (uint8_t)(t % 60U); t /= 60U;
    *hr = (uint8_t)(t % 24U); t /= 24U;

    /* t = days since 1970-01-01 */
    uint32_t y = 1970U;
    for (;;) {
        bool leap = (y % 4U == 0U) && ((y % 100U != 0U) || (y % 400U == 0U));
        uint32_t days_in_y = leap ? 366U : 365U;
        if (t < days_in_y) break;
        t -= days_in_y;
        y++;
    }
    *yr = (uint16_t)y;

    bool leap = (y % 4U == 0U) && ((y % 100U != 0U) || (y % 400U == 0U));
    static const uint8_t dim[12] = {31,28,31,30,31,30,31,31,30,31,30,31};
    uint8_t m;
    for (m = 0U; m < 12U; m++) {
        uint8_t d = dim[m] + (uint8_t)((m == 1U && leap) ? 1U : 0U);
        if (t < (uint32_t)d) break;
        t -= (uint32_t)d;
    }
    *mo = m + 1U;
    *dy = (uint8_t)(t + 1U);
}

static void ntp_recv_cb(void *arg, struct udp_pcb *pcb, struct pbuf *p,
                         const ip_addr_t *addr, u16_t port)
{
    (void)arg; (void)addr; (void)port;

    if (p->tot_len >= 48U) {
        uint8_t buf[48];
        pbuf_copy_partial(p, buf, 48U, 0U);

        /* Transmit timestamp: bytes 40-43, big-endian seconds since 1900 */
        uint32_t ntp_secs = ((uint32_t)buf[40] << 24U) |
                            ((uint32_t)buf[41] << 16U) |
                            ((uint32_t)buf[42] <<  8U) |
                             (uint32_t)buf[43];

        if (ntp_secs > NTP_EPOCH_DELTA) {
            s_unix_base = ntp_secs - NTP_EPOCH_DELTA;
            s_sync_ms   = sys_now();
            s_synced    = true;
        }
    }

    pbuf_free(p);
    udp_remove(pcb);
}

void ntp_client_init(const ip_addr_t *server_ip)
{
    struct udp_pcb *pcb = udp_new();
    if (pcb == NULL)
        return;

    uint8_t pkt[48] = {0};
    pkt[0] = 0x1BU;  /* LI=0, VN=3, Mode=3 (client) */

    struct pbuf *p = pbuf_alloc(PBUF_TRANSPORT, 48U, PBUF_RAM);
    if (p == NULL) {
        udp_remove(pcb);
        return;
    }
    memcpy(p->payload, pkt, 48U);

    udp_recv(pcb, ntp_recv_cb, NULL);
    udp_sendto(pcb, p, server_ip, NTP_PORT);
    pbuf_free(p);
    /* pcb is freed inside ntp_recv_cb after the response arrives */
}

bool ntp_is_synced(void)
{
    return s_synced;
}

uint32_t ntp_get_unix_time(void)
{
    if (!s_synced)
        return 0U;
    return s_unix_base + (sys_now() - s_sync_ms) / 1000U;
}

void ntp_format_iso8601(char *buf, size_t len)
{
    if (!s_synced || len < 21U) {
        if (len > 0U) buf[0] = '\0';
        return;
    }

    uint16_t yr; uint8_t mo, dy, hr, mn, sc;
    unix_to_datetime(ntp_get_unix_time(), &yr, &mo, &dy, &hr, &mn, &sc);

    snprintf(buf, len, "%04u-%02u-%02uT%02u:%02u:%02uZ",
             (unsigned)yr, (unsigned)mo, (unsigned)dy,
             (unsigned)hr, (unsigned)mn, (unsigned)sc);
}
