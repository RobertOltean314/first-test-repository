#ifndef NTP_CLIENT_H
#define NTP_CLIENT_H

#include <stdint.h>
#include <stdbool.h>
#include "lwip/ip_addr.h"

void     ntp_client_init(const ip_addr_t *server_ip);
bool     ntp_is_synced(void);
uint32_t ntp_get_unix_time(void);

/* Fill buf with "YYYY-MM-DDTHH:MM:SSZ" (21 bytes including null). */
void     ntp_format_iso8601(char *buf, size_t len);

#endif /* NTP_CLIENT_H */
