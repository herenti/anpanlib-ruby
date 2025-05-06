/
Anpanlib, the ruby version.
Work in progress.
Made by herenti, with some inspiration from other chatango libraries.
TODO: add classes and get rid  of the manager?
/



require "socket"
require "uri"
require "net/http"

$username = ""
$password = ""

$manager = {}

$room_list = ["garden"]

prefix = "$"

nameColor = "000000"
fontSise = "11"
fontColor = "000000"

channels = {

    "none": 0,
    "red": 256,
    "blue": 2048,
    "shield": 64,
    "staff": 128,
    "mod": 32768,
    }

$default_channel = channels["blue"].to_s

sv10 = 110
sv12 = 116
sv8 =101
sv6 = 104
sv4 = 110
sv2 = 95
sv0 = 75

$tagserver_weights = [["5", sv0],["6", sv0],["7", sv0],["8", sv0],["16", sv0],["17", sv0],["18", sv0],["9", sv2],["11", sv2],["12", sv2],["13", sv2],["14", sv2],["15", sv2],["19", sv4],["23", sv4],["24", sv4],["25", sv4],["26", sv4],["28", sv6],["29", sv6],["30", sv6],["31", sv6],["32", sv6],["33", sv6],["35", sv8],["36", sv8],["37", sv8],["38", sv8],["39", sv8],["40", sv8],["41", sv8],["42", sv8],["43", sv8],["44", sv8],["45", sv8],["46", sv8],["47", sv8],["48", sv8],["49", sv8],["50", sv8],["52", sv10],["53", sv10],["55", sv10],["57", sv10],["58", sv10],["59", sv10],["60", sv10],["61", sv10],["62", sv10],["63", sv10],["64", sv10],["65", sv10],["66", sv10],["68", sv2],["71", sv12],["72", sv12],["73", sv12],["74", sv12],["75", sv12],["76", sv12],["77", sv12],["78", sv12],["79", sv12],["80", sv12],["81", sv12],["82", sv12],["83", sv12],["84", sv12]]


def g_server(group)
    group = group.gsub(/[-_]/, "q")
    fnv = group[0,5].to_i(36).to_f
    if group.length > 6
        lnv = [group[6,[3, (group.length - 5)].min].to_i(36), 1000].max
    else
        lnv = 1000
    end
    num = (fnv / lnv) % 1
    anpan, s_number = 0,0
    maxnum = $tagserver_weights.map{|x| x[1]}.inject { |sum, x| sum + x }
    for x in $tagserver_weights
        anpan += x[1].to_f / maxnum
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

$pm_server = "c1.chatango.com"
$pm_port = 5222

def pm_login()
    $manager["pm_ready"] = "T"
    cumsock = TCPSocket.new $pm_server, $pm_port
    $manager["pm_socket"] = cumsock
    $manager["pm_wbyte"] = "".b
    _auth = Auth($username, $password)
    pm_send("tlogin", _auth, "2")
    $manager["pm_ready"] = "F"
end

def pm_send(*x)
    data = x.join(":").encode()
    if $manager["pm_ready"] == "T"
        byte = "\x00".b
    else
        byte = "\r\n\x00".b
    end
    $manager["pm_wbyte"] += data+byte
end

#chat stuff

def chat_login(chat)
    chat_port = 443
    chat_server = g_server(chat)
    chat_id = rand(10 ** 15 .. 10 ** 16).to_s
    cumsock = TCPSocket.new chat_server, chat_port
    $manager["chat_sockets"][chat] = cumsock
    $manager["chatinfo"][chat] = {}
    $manager["chatinfo"][chat]["history"] = []
    $manager["chat_ready"][chat] = "T"
    $manager["chats_wbyte"][chat] = "".b
    $manager["chat_channel"][chat] = $default_channel
    chat_send(chat, 'bauth', chat, chat_id, $username, $password)
    $manager["chat_ready"][chat] = "F"
end

def chat_send(chat, *x)
    data = x.join(":").encode()
    if $manager["chat_ready"][chat] == "T"
        byte = "\x00".b
    else
        byte = "\r\n\x00".b
    end
    $manager["chats_wbyte"][chat] += data+byte

end

#The main bakery

def bootup
    $manager["tasks"] = []
    $manager["chat_sockets"] = {}
    $manager["chats_wbyte"] = {}
    $manager["chat_channel"] = {}
    $manager["chatinfo"] = {}
    $manager["ghistory"] = {}
    $manager["uids"] = {}
    $manager["chat_ready"] = {}
    pm_login()
    for i in $room_list
        chat_login(i)
    end
    breadbun()
end

def breadbun()
    $manager["cake"] = "T"
    read_byte = "".b
    while $manager["cake"] == "T"
        $manager["sendoff"] = {}
        connections = $manager["chat_sockets"].values
        connections.append($manager["pm_socket"])

        for i in $manager["chats_wbyte"].keys
            if $manager["chats_wbyte"][i] != "".b
                $manager["sendoff"][$manager["chat_sockets"][i]] = [i, $manager["chats_wbyte"][i]]
            end
        end

        write_sock = $manager["sendoff"].keys

        if $manager["pm_wbyte"] != "".b
            write_sock.append($manager["pm_socket"])
            $manager["sendoff"][$manager["pm_socket"]] = ["pm", $manager["pm_wbyte"]]
        end

        r, w, e = IO.select(connections, write_sock, [], 0.05)
        if r != nil
            for i in r
                while not read_byte.end_with?("\x00".b)
                    read_byte += i.recv(1024)
                end
                data = []
                for x in read_byte.encode("utf-8").split("\x00")
                    x = x.rstrip
                    data.append(x.split(":"))
                end
                for x in data
                    event_call(x)
                end
                read_byte = "".b
            end
        end
        if w != nil
            for i in w
                content = $manager["sendoff"][i][1]
                _type = $manager["sendoff"][i][0]
                i.puts(content)
                if _type == "pm"
                    $manager["pm_wbyte"] = "".b
                else
                    $manager["chats_wbyte"][_type] = "".b
                end
            end
        end
    end
end

def event_call(x)
    puts x.inspect
end

bootup()
