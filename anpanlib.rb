/
Anpanlib, the ruby version.
Work in progress.
Made by herenti, with some inspiration from other chatango libraries.
todo, chat thread tasks as bunfilling, more history, more room and pm events, send pm messages
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

def html_yeet(x)
    x = x.gsub(/<.*?>/, "")
    x = x.gsub(/[<>]/, "")
    return
end

def unescape(x)
    return CGI::unescapeHTML(x)
end

def escape(x)
    return CGI::escapeHTML(x)
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

def font_parse(string, fontcolor, fontsize)
    acceptable = ["<b>","</b>", "</font>","<u>","</u>", "<i>","</i>"]
    scanned = string.scan(/<(.*?)>/)
    for i in scanned
        i = i[0]
        i = "<#{i}>"
        if i.downcase.include? "<font color=\"#"
            _color = i.match(/<font color=\"#(.*?)">/)
            if _color != nil
                _color = _color.captures
            else
                string = "Invalid font tag detected."
                break
            end
            if _color
                if _color[0].length != 6
                    string = "Invalid font tag detected."
                    break
                end
                string = string.gsub(i,"<f x#{_color[0]}=\"0\">")
                string = string.gsub("</font>", "<f x#{fontsize}#{fontcolor}=\"0\">")
            end
        else
            if not acceptable.include? i
                string = string.gsub(i, "")
            end
        end
    end
    if string.scan("<").length != string.scan(">").length
        string = "Unclosed &lt; &gt; tags detected."
    end
    return string
end

def event_call(_class, event, *data)

    event = "event_"+event
    if _class.respond_to?(event)
        _class.send(event, *data)
    end
end

class Bunfilling

    def initialize(args)
        @args = args
        to_set()
    end

    def set_attr(key, value)
        singleton_class.class_eval { attr_accessor "#{key}" }
        send("#{key}=", value)
    end

    def to_set
        for x in @args
            set_attr(x[0], x[1])
        end
    end

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

    #events

    def event_OK(data)
        pm_send("wl")
        pm_send("getblock")
        pm_send("getpremium", "1")
    end

    def event_msg(data)
        content = CGI::unescapeHTML(data.drop(5).join.gsub(/<.*?>/, ""))
        from = data[1]
        puts "pm message from [#{from}]: message content: [#{content}]"
    end



end

#chat stuff
class Chat

    attr_accessor :chat,:prefix, :namecolor, :bakery, :fontsize, :fontcolor, :cumsock, :wbyte, :channel, :chat_ready, :pingtask, :ctype, :owner, :mods, :history

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
        @namecolor = "C7A793"
        @fontcolor = "F7DCCE"
        @fontsize = "10"
        @ctype = "chat"
        @prefix = "$"
        @history = []
        chat_login()
    end

    def fart
        choice = ["thbt","tttbbbbtt", "tttttthhhhhhbbbbbttt", "flubflublbblb","brrrrrraapppp","brrrurnnnntttt", " ", "shhhhppppplaaatt", "surplat", "bromp"]
        schoice = ["I feel a fart coming on... ", "I am so gassy... ", "Oh nooo im gonna fart... ", "I hope this is not a shart... ", "Please excuse my gas... ", "This might be a stinky one.... ", "Welcome to the fartfest... "]
        _num = Random.new.rand(1..5)
        _choice = ""
        for i in Array.new(_num)
            _choice += choice.sample
        end
        if _choice == " "
            _choice = "   - It was a silent one...."
        end
        return (schoice.sample + _choice)
    end

    def chat_fart
        while true
            chat_post(fart)
            sleep 60*30
        end
    end

    def chat_login
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

    def get_last_message(_user)
        userhist = []
        for i in @bakery.connections
            if i.ctype == "chat"
                for x in i.history
                    if x.user.downcase == _user.downcase
                        userhist.append(x)
                    end
                end
            end
        end
        userhist = userhist.sort{ |a,b| a.time <=> b.time }
        message = userhist[-1]
        return message
    end

    def chat_post(msg)
        msg = msg.to_s
        msg = msg.gsub(@password, 'anpan')
        msg = font_parse(msg, @fontcolor, @fontsize)
        font = "<n#{@namecolor}/><f x#{@fontsize}#{@fontcolor}=\"0\">"
        if msg.length > 2500
            message, rest = msg[0..2499], msg[2500..-1]
            chat_send('bm', 'fuck', @channel, "#{font}#{message}</f>")
            Thread.new{sleep 1; chat_post(rest)}
        else
            chat_send('bm', 'fuck', @channel, "#{font}#{msg}</f>")
        end
    end

    def r_uids(uid, user)
        key, value = uid.downcase, user.downcase
        if not @bakery.uids.keys.include? key
            @bakery.uids[key] = [value]
        else
            values = @bakery.uids[key]
            if not values.include? value
                values.append(value)
                @bakery.uids[key] = values
            end
        end
    end

    def getuser(user, _alias, uid)
        if user == ""
            user = "None"
        end
        if user != "None"
            r_uids(uid, user)
        end
        if user == "None"
            if _alias == ""
                user = "None"
            elsif _alias == "None"
                user = "NOne"
            else
                user = _alias
            end
        end
        return user
    end

    #events

    def event_b(data)
        ucontent = data.drop(9).join(":")
        _id = ucontent.match("<n(.*?)/>")
        if _id
            _id = _id.captures[0]
        end
        user = data[1]
        _alias = data[2]
        content = unescape(ucontent.gsub(/<.*?>/, ""))
        message = Bunfilling.new([
                                  ["user", getuser(data[1], data[2], data[3])],
                                  ["cid", data[4]],
                                  ["uid", data[3]],
                                  ["time", data[0]],
                                  ["sid", data[5]],
                                  ["ip", data[6]],
                                  ["content", content],
                                  ["chat", self]
                                 ])
        @history.append(message)
        event_call(@bakery, "onpost", message)
    end

    def event_inited(data)
        chat_send("getpremium", "1")
        chat_send("g_participants", "start")
        chat_send("getbannedwords")
        chat_send("msgbg", "1")
    end

    def event_denied(data)
        puts "login fail: #{@chat}"
    end

    def event_ok(data)
        @owner = data[0]
        @mods = data[6].split(";")
    end

    def event_i(data)
        ucontent = data.drop(9).join(":")
        _id = ucontent.match("<n(.*?)/>")
        if _id
            _id = _id.captures[0]
        end
        content = unescape(ucontent.gsub(/<.*?>/, ""))
        message = Bunfilling.new([
                                  ["user", getuser(data[1], data[2], data[3])],
                                  ["cid", data[4]],
                                  ["uid", data[3]],
                                  ["time", data[0]],
                                  ["sid", data[5]],
                                  ["ip", data[6]],
                                  ["content", content],
                                  ["chat", self]
                                 ])
        @history.append(message)
    end

end


#The main bakery

class Bakery

    attr_accessor :uids, :anpan_is_tasty, :connections, :username

    def initialize(username, password, room_list)
        @username = username
        @password = password
        @tasks = []
        @connections = []
        @room_list = room_list
        @anpan_is_tasty = true
        @rbyte = "".b
        @uids = {}
        bake()
    end

    def bake
        for i in @room_list
            @connections << Chat.new(i, @username, @password, self)
        end
        @connections << Pm.new(@username, @password, self)
        breadbun()
    end

    def get_chat(_chat)
        for i in @connections
            if i.ctype == "chat"
                if i.chat == _chat
                    return i
                end
            end
        end
    end

    def whois(string)
        a = [string]
        while true
            l = a.length
            for n in a
                i = _whois(n)
                if i.length > 0
                    a += i
                else
                    a = ['no accounts for that user']
                    break
                end
                a = a.to_set.to_a
            end
            if l == a.length
                break
            end
        end
        return a.join(", ")
    end

    def _whois(string)
        a = []
        for key, value in @uids
            i = @uids[key]
            if i.include? string
                a += i
            end
        end
        return a.to_set.to_a
    end


    def breadbun
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
                            @rbyte += i.recv(1024)
                    end
                    data = []
                    for x in @rbyte.split("\x00")
                        x = x.rstrip
                        data.append(x.split(":"))
                    end
                    for x in data
                        if x.length > 0
                            for c in @connections
                                if c.cumsock == i
                                    event_call(c, x[0], x.drop(1))
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
