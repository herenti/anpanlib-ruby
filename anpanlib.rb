/
Anpanlib, the ruby version.
Work in progress.
Made by herenti, with some inspiration from other chatango libraries.
/



require "socket"
require "uri"
require "net/http"


$channels = {

    "none": 0,
    "red": 256,
    "blue": 2048,
    "shield": 64,
    "staff": 128,
    "mod": 32768,
    }

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

def Auth(user, pass)
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


#pm stuff
class Pm

    attr_accessor :cumsock, :wbyte, :pm_ready, :pingtask

    def initialize(username, password, bakery)
        @username = username
        @password = password
        @pm_ready = true
        @wbyte = "".b
        @bakery = bakery
        pm_login()
    end

    def pm_login()
        @cumsock = TCPSocket.new "c1.chatango.com", 5222
        _auth = Auth(@username, @password)
        pm_send("tlogin", _auth, "2")
        @pm_ready = false
        @pingtask = Thread.new{pingtask}
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
            chat_send("")
            sleep 30
        end
    end
end

#chat stuff
class Chat

    attr_accessor :chat,:prefix, :namecolor, :fontsize, :fontcolor, :cumsock, :wbyte, :channel, :chat_ready, :chatinfo, :pingtask

    def initialize(chat, username, password, bakery)
        @chat = chat
        @username = username
        @password = password
        @wbyte = "".b
        @chat_ready = true
        @channel = $channels["blue"].to_s
        @bakery = bakery
        @namecolor = "000000"
        @fontcolor = "000000"
        @fontsize = "12"
        chat_login()
    end

    def chat_login()
        chat_id = rand(10 ** 15 .. 10 ** 16).to_s
        @cumsock = TCPSocket.new g_server(@chat), 443
        chat_send('bauth', chat, chat_id, @username, @password)
        @chat_ready = false
        @pingtask = Thread.new{chat_ping}
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


    #events

    def event_b(data)
        puts data.inspect
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
            @connections.append(Chat.new(i, @username, @password, self))
        end
        @connections.append(Pm.new(@username, @password, self))
        breadbun()
    end

    def breadbun()
        while @anpan_is_tasty
            read_sock = []
            write_sock = []
            for i in @connections
                read_sock.append(i.cumsock)
            end
            for i in @connections
                if i.wbyte != "".b
                    write_sock.append(i.cumsock)
                end
            end
            r, w, e = IO.select(read_sock, write_sock, [], 0.05)
            if r != nil
                for i in r
                    while not @rbyte.end_with?("\x00".b)
                        @rbyte += i.recv(1024)
                    end
                    data = []
                    for x in @rbyte.encode("utf-8").split("\x00")
                        x = x.rstrip
                        data.append(x.split(":"))
                    end
                    for x in data
                        if x.length > 0
                            puts x.inspect
                            #event = "event_"+x[0]
                            #if respond_to?(event, :include_private)
                                #send(event, x.drop(1))
                            #end
                        end
                    end
                    @rbyte = "".b
                end
            end
            if w != nil
                for i in w
                    for x in @connections
                        if x.cumsock == i
                            puts x.wbyte
                            i.puts(x.wbyte)
                            x.wbyte = "".b
                        end
                    end
                end
            end
        end
    end
end

room_list = ["garden"]
run = Bakery.new("anpanbot", "", room_list)
