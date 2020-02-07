#include "include/seastarkv.hh"
#include "include/net_server.hh"
#include "include/reply_builder.hh"
#include "include/req_server.hh"

distributed<network_server> net_server;

void network_server::start() {
     listen_options lo;
     lo.reuse_address = true;
     _listener = engine().listen(make_ipv4_address({_port}), lo);
     keep_doing([this] {
        return _listener->accept().then([this] (connected_socket fd, socket_address addr) mutable {
            return seastar::async([this, &fd, addr] {
                //++_stats._connections_total;
                //++_stats._connections_current;

                // The tenant id for this connection
                int t = (this->tid++)%NUM_CONTEXTS;
                if (net::ntoh(addr.u.in.sin_addr.s_addr) == 167772428 )
                {
                    t = 0;
                }

                auto conn = make_lw_shared<connection>(std::move(fd), addr, t);
                cout << addr << " " << engine().cpu_id() << " " << t << "\n";
                do_until([conn] { return conn->_in.eof(); }, [this, conn] {
                    return with_gate(_request_gate, [this, conn] {
                        return conn->handler.handle(conn->_in, conn->_out, conn->tenant_id).then([this, conn] {
                            return conn->_out.flush();
                        });
                    });
                }).finally([this, conn] {
                    //--_stats._connections_current;
                    return conn->_out.close().finally([conn]{});
                });
            });
        });
    }).or_terminate();
}