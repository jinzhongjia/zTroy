//! KCP - A Better ARQ Protocol Implementation
//!
//! This is zig Implementation for KCP
//! Copyright (c) 2020-2024 [Jinzhongjia](https://github.com/jinzhongjia),
//! Mail: mail@nvimer.org
//!
//! Features:
//! + Average RTT reduce 30% - 40% vs traditional ARQ like tcp.
//! + Maximum RTT reduce three times vs tcp.
//! + Lightweight, distributed as a single source file.
//!
//! KCP Repository: https://github.com/skywind3000/kcp

/// control block
const CB = struct {
    /// session id
    conv: u32,
    /// mtu
    mtu: u32,
    /// mss
    mss: u32,
    /// state
    state: bool,
    /// sended un ack
    snd_una: u32,
    /// next send id
    snd_nxt: u32,
    /// next receive id
    rcv_nxt: u32,
    /// not used
    ts_recent: u32,
    /// not used
    ts_lastack: u32,
    /// slow start threshold
    ssthresh: u32,
    /// rto
    rx_rto: i32,
    /// Calculate intermediate variables of rx_rto
    rx_rttval: i32,
    /// Calculate intermediate variables of rx_rto
    rx_srtt: i32,
    /// Calculate intermediate variables of rx_rto
    rx_minrto: i32,
    snd_wnd: u32,
    rcv_wnd: u32,
    rmt_wnd: u32,
    cwnd: u32,
    probe: u32,
    current: u32,
    interval: u32,
    ts_flush: u32,
    xmit: u32,
    nrcv_buf: u32,
    nsnd_uf: u32,
};

/// message segment
const Segment = struct {
    /// session id, the peers need to use the same session id
    conv: u32,
    /// command
    cmd: u32,
    /// shard id
    frg: u32,
    /// available window number
    wnd: u32,
    // send timestamp
    ts: u32,
    /// id
    sn: u32,
    /// current un ack id
    una: u32,
    /// length
    len: u32,
    /// resend time stamp
    resendts: u32,
    /// Retransmission TimeOut
    rto: u32,
    /// fast tack
    fastack: u32,
    /// transmission numbers
    xmit: u32,
    /// data
    data: []u8,
};
