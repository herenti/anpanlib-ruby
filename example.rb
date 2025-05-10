require_relative "anpanlib"
require_relative "genrainbow" #this code can be found in the "extra-stuff" repository. i do not own the rainbow code.
require_relative "translate"

class Anpan < Bakery

    def post_await(chat, *args)
        for i in args
            chat.chat_post(i)
            sleep 1
        end
    end

    def event_onpost(chat, message)
        content = message.content
        if content.length > 0
            if content.include? "youtusernamehere" #lol
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
                _prefix = true
            else
                _prefix = false
            end
            func = func[1..-1]
            if _prefix
                if $locked_rooms.include? chat.chat
                    return
                end
                if func == "say"
                    chat.chat_post(string)
                elsif func == "rainbow"
                    chat.chat_post(Rainbow.new.rainbow_text(string))
                elsif func == "tran"
                    chat.chat_post(Translate.new.tran(string))
                elsif func == "rsend"
                    _chat, _message = string.split(" ", 2)

                    _chat = get_chat(_chat)
                     text = Rainbow.new.rainbow_text(_message)


                     _postawait = []

                     while text.length > 0
                         _build = ""
                         _text = text.split("<font")
                         _text = _text.drop(1)
                         for i in _text
                            _part =  "<font#{i}"
                            if _build.length < 2400
                                _build += _part
                            else
                                break
                            end
                         end
                         _postawait.append(_build)
                         text = text.gsub(_build, "")
                         _build = ""
                     end
                     Thread.new{post_await(_chat, *_postawait)}

                elsif func == "msend"
                    _chat, _message = string.split(" ", 2)
                    get_chat(_chat).chat_post(_message)
                elsif func == "check"
                    puts chat.bakery.uids
                    chat.chat_post("done")
                elsif func == "whois"
                    chat.chat_post(chat.bakery.whois(string))
                elsif func == "seen"
                    _user = string.downcase
                    begin
                        _message = chat.get_last_message(_user)
                        chat.chat_post("[<b>#{_message.user}</b>] was last seen saying [<b>#{_message.content}</b>] in the room [<b>#{_message.chat}</b>]")
                    rescue
                        chat.chat_post("I have not seen them around yet.")
                    end

                end
            end
        end

    end
end



room_list = []

$locked_rooms = []

Anpan.new("username", "password", room_list)
