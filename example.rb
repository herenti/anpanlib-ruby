require_relative "anpanlib"
require_relative "commands"

class Anpan < Bakery

    def event_onpost(message)

        banned_terms = []
        chat = message.chat

        if message.user != @username
            content = message.content
            if content.length > 0
                if content.include? "herenti" #lol
                    puts "chat: #{chat.chat}: user: #{message.user} message: #{content}"
                end
                data = content.split(" ")
                if data.length > 1
                    func, string = data[0], data.drop(1)
                else
                    func, string = data[0].downcase, [""]
                end
                string = string.join(" ")
                if func[0] == chat.prefix
                    func = func[1..-1]
                    if $locked_rooms.include? chat.chat
                        return
                    end

                    _commands = Commands.new
                    func = "command_"+func
                    for i in banned_terms
                        if string.downcase.include? i
                            chat.chat_post("Command request contains banned terms.")
                            return
                        end
                    end
                    if _commands.respond_to?(func)
                        chat.chat_post(_commands.send(func, message, string))
                    end
                end
            end
        end

    end
end



room_list = []

$locked_rooms = []

Anpan.new("", "", room_list)
