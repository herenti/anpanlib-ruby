/
Anpanlib, the ruby version.
Work in progress.
Made by herenti, with some inspiration from other chatango libraries.
/



require "socket"
require "uri"
require "net/http"
require "cgi"

def tagserver_weights

    sv10 = 110
    sv12 = 116
    sv8 =101
    sv6 = 104
    sv4 = 110
    sv2 = 95
    sv0 = 75

    weights = [["5", sv0],["6", sv0],["7", sv0],["8", sv0],["16", sv0],["17", sv0],["18", sv0],["9", sv2],["11", sv2],["12", sv2],["13", sv2],["14", sv2],["15", sv2],["19", sv4],["23", sv4],["24", sv4],["25", sv4],["26", sv4],["28", sv6],["29", sv6],["30", sv6],["31", sv6],["32", sv6],["33", sv6],["35", sv8],["36", sv8],["37", sv8],["38", sv8],["39", sv8],["40", sv8],["41", sv8],["42", sv8],["43", sv8],["44", sv8],["45", sv8],["46", sv8],["47", sv8],["48", sv8],["49", sv8],["50", sv8],["52", sv10],["53", sv10],["55", sv10],["57", sv10],["58", sv10],["59", sv10],["60", sv10],["61", sv10],["62", sv10],["63", sv10],["64", sv10],["65", sv10],["66", sv10],["68", sv2],["71", sv12],["72", sv12],["73", sv12],["74", sv12],["75", sv12],["76", sv12],["77", sv12],["78", sv12],["79", sv12],["80", sv12],["81", sv12],["82", sv12],["83", sv12],["84", sv12]]

    return weights
end

def g_server(group)
    group = group.gsub(/[-_]/, "q")
    anko = group.length > 6 ? [group[6,[3, (group.length - 5)].min].to_i(36), 1000].max : 1000
    num = ((group[0, [5, group.length].min].to_i(base=36).to_f) / anko) % 1
    anpan, s_number = 0,0
    for x in tagserver_weights()
        anpan += x[1].to_f / (tagserver_weights().sum{|a| a[1]})
        if(num <= anpan) and s_number == 0
            s_number += x[0].to_i
            break
        end
    end
    return "s" + s_number.to_s + ".chatango.com"
end

def _Auth(user, pass)
    uri = URI('http://chatango.com/login')
    params = {
        "user_id": user,
        "password": pass,
        "storecookie": "on",
        "checkerrors": "yes"
    }
    uri.query = URI.encode_www_form(params)
    res = Net::HTTP.get_response(uri)
    _auth = res['set-cookie'].match("auth.chatango.com=(.*?);").captures
    _auth = _auth[0]
    return _auth
end

def trunc(str, length)
    addition = str.length > length ? '...' : ''
    "#{str.truncate(length, omission: '')}#{addition}"
end

def font_parse(x)
    _colors = x.match("<font color=\"#(.*?)\">").captures
    _part = x.split("<font color=\"#")
    _r = []
    _part = _part.reject { |element| element.empty? }
    for i in _part
        _part2 = i.split("\">", 2)
        _color = _part2[0]
        if _color != ""
            _rebuild = "#{_color}=\"0\">#{_part2[1]}"
            _r.append(_rebuild)
        end

    end
    _final = _r.map{|item| "<f x"+item}.join
    puts _final
    return _final
end


#pm stuff
class Pm

    attr_accessor :cumsock, :wbyte, :pm_ready, :pingtask, :ctype

    def initialize(username, password, bakery)
        @username = username
        @password = password
        @pm_ready = true
        @wbyte = "".b
        @bakery = bakery
        @ctype = "pm"
        @_auth = _Auth(@username, @password)
        pm_connect()
    end

    def pm_connect
        @cumsock = TCPSocket.new "c1.chatango.com", 5222
        pm_login()
        @pingtask = Thread.new{pm_ping}
    end

    def pm_login
        pm_send("tlogin", @_auth, "2")
        @pm_ready = false


    end

    def pm_send(*x)

        data = x.join(":").encode()
        if @pm_ready
            byte = "\x00".b
        else
            byte = "\r\n\x00".b
        end
        @wbyte += data+byte
    end

    def pm_ping
        while true
            sleep 30
            pm_send("")
            sleep 30
        end
    end
end

#chat stuff
class Chat

    attr_accessor :chat,:prefix, :namecolor, :fontsize, :fontcolor, :cumsock, :wbyte, :channel, :chat_ready, :chatinfo, :pingtask, :ctype

    def initialize(chat, username, password, bakery)
        @chat = chat
        @username = username
        @password = password
        @wbyte = "".b
        @chat_ready = true
        @channels = {
            none: 0,
            red: 256,
            "blue": 2048,
            shield: 64,
            staff: 128,
            mod: 32768,
            }
        @channel = @channels[:blue].to_s
        @bakery = bakery
        @namecolor = "000000"
        @fontcolor = "000000"
        @fontsize = "12"
        @ctype = "chat"
        @prefix = "$"
        chat_login()
    end

    def chat_login()
        chat_id = rand(10 ** 15 .. 10 ** 16).to_s
        @cumsock = TCPSocket.new g_server(@chat), 443
        @pingtask = Thread.new{chat_ping}
        chat_send('bauth', chat, chat_id, @username, @password)
        @chat_ready = false

    end

    def chat_send(*x)
        data = x.join(":").encode()
        if @chat_ready
            byte = "\x00".b
        else
            byte = "\r\n\x00".b
        end
        @wbyte += data+byte

    end

    def chat_ping
        while true
            chat_send("")
            sleep 30
        end
    end

    def chat_post(msg)
        msg = msg.to_s
        msg = msg.gsub(@password, 'anpan')
        msg = font_parse(msg)
        font = "<n#{@namecolor}/><f x#{@fontsise}#{@fontcolor}=\"0\">"
        if msg.length > 2500
            message, rest = trunc(msg, 2500), msg.drop(2500).join("")
            chat_send('bm', 'fuck', @channel, "#{font}#{message}</f>")
            chat_post(rest)
        else
            chat_send('bm', 'fuck', @channel, "#{font}#{msg}</f>")
        end
    end

    #events

    def event_b(data)
        ucontent = data.drop(9).join(":")
        _id = ucontent.match("<n(.*?)/>")
        if _id
            _id = _id.captures[0]
        end
        content = CGI::unescapeHTML(ucontent.gsub(/<.*?>/, ""))
        if @bakery.respond_to?("onpost")
            @bakery.onpost(self, content)
        end
    end

end


#The main bakery

class Bakery

    def initialize(username, password, room_list)
        @username = username
        @password = password
        @tasks = []
        @connections = []
        @room_list = room_list
        @anpan_is_tasty = true
        @rbyte = "".b
        bake()
    end

    def bake
        for i in @room_list
            @connections << Chat.new(i, @username, @password, self)
        end
        @connections << Pm.new(@username, @password, self)
        breadbun()
    end

    def breadbun()
        while @anpan_is_tasty
            read_sock = []
            write_sock = []
            for i in @connections
                if i != nil
                    read_sock.append(i.cumsock)
                end
            end
            for i in @connections
                if i.wbyte != "".b
                    if i != nil
                        write_sock.append(i.cumsock)
                    end
                end
            end
            r, w, e = IO.select(read_sock, write_sock, [], 0.05)
            if r != nil
                for i in r
                    while not @rbyte.end_with?("\x00".b)
                            @rbyte += i.recv(1024) #this is nil when its the pm socket
                    end
                    data = []
                    for x in @rbyte.encode("utf-8").split("\x00")
                        x = x.rstrip
                        data.append(x.split(":"))
                    end
                    for x in data
                        if x.length > 0
                            for c in @connections
                                if c.cumsock == i
                                    event = "event_"+x[0]
                                    if c.respond_to?(event)
                                        c.send(event, x.drop(1))
                                    end
                                end
                            end
                        end
                    end
                    @rbyte = "".b
                end
            end
            if w != nil
                for i in w
                    for x in @connections
                        if x.cumsock == i
                            i.puts(x.wbyte)
                            x.wbyte = "".b
                        end
                    end
                end
            end
        end
    end
end
