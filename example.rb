require_relative "anpanlib"

class Anpan < Bakery
    def onpost(chat, message)
        if message.length > 0
            data = message.split(" ")
            p
            if data.length > 1
                func, string = data[0], data.drop(1)
            else
                func, string = data[0].downcase, [""]
            end
            string = string.join(" ")
            if func[0] == chat.prefix
                _prefix = true
            else
                _prefix = false
            end
            func = func[1..-1]
            if _prefix
                if func == "say"
                    chat.chat_post(string)
                end
            end
        end

    end
end

room_list = ["dungeon"]
Anpan.new("", "", room_list)
