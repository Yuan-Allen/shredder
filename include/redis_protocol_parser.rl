/*
* Pedis is free software: you can redistribute it and/or modify
* it under the terms of the GNU Affero General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* You may obtain a copy of the License at
*
*     http://www.gnu.org/licenses
*
* Unless required by applicable law or agreed to in writing,
* software distributed under the License is distributed on an
* "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
* KIND, either express or implied.  See the License for the
* specific language governing permissions and limitations
* under the License.
* 
*  Copyright (c) 2016-2026, Peng Jian, pstack@163.com. All rights reserved.
*
*/

/** This protocol parser was inspired by the memcached app,
  which is the example in Seastar project.
**/

#include "core/ragel.hh"
#include <memory>
#include <iostream>
#include <algorithm>
#include <functional>

using namespace seastar;

%%{

machine redis_resp_protocol;

access _fsm_;

action mark {
    g.mark_start(p);
}

action start_blob {
    g.mark_start(p);
    _size_left = _arg_size;
}
action start_command {
    g.mark_start(p);
    _size_left = _arg_size;
}

action advance_blob {
    auto len = std::min((uint32_t)(pe - p), _size_left);
    _size_left -= len;
    p += len;
    if (_size_left == 0) {
      _args_list.push_back(str());
      p--;
      fret;
    }
    p--;
}

action advance_command {
    auto len = std::min((uint32_t)(pe - p), _size_left);
    _size_left -= len;
    p += len;
    if (_size_left == 0) {
      _command = str();
      p--;
      fret;
    }
    p--;
}


crlf = '\r\n';
u32 = digit+ >{ _u32 = 0;}  ${ _u32 *= 10; _u32 += fc - '0';};
args_count = '*' u32 crlf ${_args_count = _u32;};
blob := any+ >start_blob $advance_blob;
quit = "quit"i ${_command = command::quit;};
info = "info"i ${_command = command::info;};
js = "js"i ${_command = command::js;};
set = "set"i ${_command = command::set;};
mset = "mset"i ${_command = command::mset;};
get = "get"i ${_command = command::get;};
mget = "mget"i ${_command = command::mget;};
del = "del"i ${_command = command::del;};
echo = "echo"i ${_command = command::echo;};
ping = "ping"i ${_command = command::ping;};
incr = "incr"i ${_command = command::incr;};
decr = "decr"i ${_command = command::decr;};
incrby = "incrby"i ${_command = command::incrby;};
decrby = "decrby"i ${_command = command::decrby;};
command_ = "command"i ${_command = command::command;};
exists = "exists"i ${_command = command::exists;};
append = "append"i ${_command = command::append;};
strlen = "strlen"i ${_command = command::strlen;};
lpush = "lpush"i ${_command = command::lpush;};
lpushx = "lpushx"i ${_command = command::lpushx;};
lpop = "lpop"i ${_command = command::lpop;};
llen = "llen"i ${_command = command::llen;};
lindex = "lindex"i ${_command = command::lindex;};
linsert = "linsert"i ${_command = command::linsert;};
lrange = "lrange"i ${_command = command::lrange;};
lset = "lset"i ${_command = command::lset;};
rpush = "rpush"i ${_command = command::rpush;};
rpushx = "rpushx"i ${_command = command::rpushx;};
rpop = "rpop"i ${_command = command::rpop;};
lrem = "lrem"i ${_command = command::lrem;};
ltrim = "ltrim"i ${_command = command::ltrim;};
hset = "hset"i ${_command = command::hset;};
hmset = "hmset"i ${_command = command::hmset;};
hdel = "hdel"i ${_command = command::hdel;};
hget = "hget"i ${_command = command::hget;};
hlen = "hlen"i ${_command = command::hlen;};
hexists = "hexists"i ${_command = command::hexists;};
hstrlen = "hstrlen"i ${_command = command::hstrlen;};
hincrby = "hincrby"i ${_command = command::hincrby;};
hincrbyfloat = "hincrbyfloat"i ${_command = command::hincrbyfloat;};
hkeys = "hkeys"i ${_command = command::hkeys;};
hvals = "hvals"i ${_command = command::hvals;};
hmget = "hmget"i ${_command = command::hmget;};
hgetall = "hgetall"i ${_command = command::hgetall;};
sadd = "sadd"i ${_command = command::sadd;};
scard = "scard"i ${_command = command::scard;};
sismember = "sismember"i ${_command = command::sismember;};
smembers = "smembers"i ${_command = command::smembers;};
srandmember = "srandmember"i ${_command = command::srandmember;};
srem = "srem"i ${_command = command::srem;};
sdiff = "sdiff"i ${_command = command::sdiff;};
sdiffstore = "sdiffstore"i ${_command = command::sdiffstore;};
sinter = "sinter"i ${_command = command::sinter;};
sinterstore = "sinterstore"i ${_command = command::sinterstore;};
sunion = "sunion"i ${_command = command::sunion;};
sunionstore = "sunionstore"i ${_command = command::sunionstore;};
smove = "smove"i ${_command = command::smove;};
spop = "spop"i ${_command = command::spop;};
type = "type"i ${_command = command::type; };
expire = "expire"i ${_command = command::expire; };
pexpire = "pexpire"i ${_command = command::pexpire; };
ttl = "ttl"i ${_command = command::ttl; };
pttl = "pttl"i ${_command = command::pttl; };
persist = "persist"i ${_command = command::persist; };
zadd = "zadd"i ${_command = command::zadd; };
zcard  = "zcard"i ${_command = command::zcard; };
zcount = "zcount"i ${_command = command::zcount; };
zincrby = "zincrby"i ${_command = command::zincrby; };
zrange = "zrange"i ${_command = command::zrange;};
zrank = "zrank"i ${_command = command::zrank; };
zrem = "zrem"i ${_command = command::zrem; };
zremrangebyrank = "zremrangebyrank"i ${_command = command::zremrangebyrank; };
zremrangebyscore = "zremrangebyscore"i ${_command = command::zremrangebyscore; };
zrevrange = "zrevrange"i ${_command = command::zrevrange; };
zrevrangebyscore = "zrevrangebyscore"i ${_command = command::zrevrangebyscore; };
zrevrank = "zrevrank"i ${_command = command::zrevrank; };
zscore = "zscore"i ${_command = command::zscore; };
zunionstore = "zunionstore"i ${_command = command::zunionstore; };
zinterstore = "zinterstore"i ${_command = command::zinterstore; };
zdiffstore = "zdiffstore"i ${_command = command::zdiffstore; };
zunion = "zunion"i ${_command = command::zunion; };
zinter = "zinter"i ${_command = command::zinter; };
zdiff = "zunion"i ${_command = command::zdiff; };
zscan = "zscan"i ${_command = command::zscan; };
zrangebylex = "zrangebylex"i ${_command = command::zrangebylex; };
zrangebyscore = "zrangebyscore"i ${_command = command::zrangebyscore; };
zlexcount = "zlexcount"i ${_command = command::zlexcount;};
zremrangebylex = "zremrangebylex"i ${_command = command::zremrangebylex; };
select = "select"i ${_command = command::select; };
geoadd = "geoadd"i ${_command = command::geoadd; };
geodist = "geodist"i ${_command = command::geodist; };
geohash = "geohash"i ${_command = command::geohash; };
geopos = "geopos"i ${_command = command::geopos; };
georadius = "georadius"i ${_command = command::georadius; };
georadiusbymember = "georadiusbymember"i ${_command = command::georadiusbymember; };
setbit = "setbit"i ${_command = command::setbit; };
getbit = "getbit"i ${_command = command::getbit; };
bitcount = "bitcount"i ${_command = command::bitcount; };
bitop = "bitop"i ${_command = command::bitop; };
bitfield = "bitfield"i ${_command = command::bitfield; };
bitpos = "bitpos"i ${_command = command::bitpos; };
pfadd = "pfadd"i ${_command = command::pfadd; };
pfcount = "pfcount"i ${_command = command::pfcount; };
pfmerge = "pfmerge"i ${_command = command::pfmerge; };

command = (quit| info| js | setbit | set | getbit | get | del | mget | mset | echo | ping | incr | decr | incrby | decrby | command_ | exists | append |
           strlen | lpushx | lpush | lpop | llen | lindex | linsert | lrange | lset | rpushx | rpush | rpop | lrem |
           ltrim | hset | hgetall |hget | hdel | hlen | hexists | hstrlen | hincrby | hincrbyfloat | hkeys | hvals | hmget | hmset |
           sadd | scard | sismember | smembers | srem | sdiffstore | sdiff | sinterstore | sinter| sunionstore | sunion | smove | srandmember | spop |
           type | expire | pexpire | persist | ttl | pttl | zadd | zcard | zcount | zincrby |
           zrangebyscore | zrank | zremrangebyrank | zremrangebyscore | zremrangebylex | zrem | zrevrangebyscore | zrevrange| zrevrank |
           zscore | zunionstore  | zinterstore | zdiffstore | zunion | zinter | zdiff | zscan | zrangebylex | zlexcount |
           zrange | select | geoadd | geodist | geohash | geopos | georadiusbymember | georadius |  bitcount |
           bitpos | bitop | bitfield |
           pfadd | pfcount | pfmerge );
arg = '$' u32 crlf ${ _arg_size = _u32;};

main := (args_count (arg command crlf) (arg @{fcall blob; } crlf)+) ${_state = state::ok;};

prepush {
    prepush();
}

postpop {
    postpop();
}

}%%

class redis_protocol_parser : public ragel_parser_base<redis_protocol_parser> {
    %% write data nofinal noprefix;
public:
    enum class state {
        error,
        eof,
        ok,
    };
    enum class command {
        quit,
        info,
        js,
        set,
        mset,
        get,
        mget,
        del,
        echo,
        ping,
        incr,
        decr,
        incrby,
        decrby,
        command,
        exists,
        append,
        strlen,
        lpush,
        lpushx,
        lpop,
        llen,
        lindex,
        linsert,
        lrange,
        lset,
        rpush,
        rpushx,
        rpop,
        lrem,
        ltrim,
        hset,
        hdel,
        hget,
        hlen,
        hexists,
        hstrlen,
        hincrby,
        hincrbyfloat,
        hkeys,
        hvals,
        hmget,
        hmset,
        hgetall,
        sadd,
        scard,
        sismember,
        smembers,
        srem,
        sdiff,
        sdiffstore,
        sinter,
        sinterstore,
        sunion,
        sunionstore,
        smove,
        srandmember,
        spop,
        type,
        expire,
        pexpire,
        ttl,
        pttl,
        persist,
        zadd,
        zcard,
        zcount,
        zincrby,
        zrange,
        zrangebyscore,
        zrank,
        zrem,
        zremrangebyrank,
        zremrangebyscore,
        zrevrange,
        zrevrangebyscore,
        zrevrank,
        zscore,
        zunionstore,
        zinterstore,
        zdiffstore,
        zunion,
        zinter,
        zdiff,
        zscan,
        zrangebylex,
        zlexcount,
        zremrangebylex,
        select,
        geoadd,
        geohash,
        geodist,
        geopos,
        georadius,
        georadiusbymember,
        setbit,
        getbit,
        bitcount,
        bitop,
        bitpos,
        bitfield,
        pfadd,
        pfcount,
        pfmerge,
    };

    state _state;
    command _command;
    uint32_t _u32;
    uint32_t _arg_size;
    uint32_t _args_count;
    uint32_t _size_left;
    std::vector<sstring>  _args_list;
public:
    void init() {
        init_base();
        _state = state::error;
        _args_list.clear();
        _args_count = 0;
        _size_left = 0;
        _arg_size = 0;
        %% write init;
    }

    char* parse(char* p, char* pe, char* eof) {
        sstring_builder::guard g(_builder, p, pe);
        auto str = [this, &g, &p] { g.mark_end(p); return get_str(); };
        %% write exec;
        if (_state != state::error) {
            return p;
        }
        // error ?
        if (p != pe) {
            p = pe;
            return p;
        }
        return nullptr;
    }
    bool eof() const {
        return _state == state::eof;
    }
};
