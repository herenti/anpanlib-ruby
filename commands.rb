require_relative "genrainbow" #this code can be found in the "extra-stuff" repository. i do not own the rainbow code.
require_relative "translate"


class Commands

    def initialize
        @admins = []
    end

    def post_await(chat, *args)
        for i in args
            chat.chat_post(i)
            sleep 2
        end
    end

    def command_say message, string
        return string
    end

    def command_rainbow message, string
        return Rainbow.new.rainbow_text(string)
    end

    def command_tran message, string
        return Translate.new.tran(string)
    end

    def command_rsend message, string
        if !@admins.include? message.user.downcase
            return "You do not have permission to use this command."
        else
            begin
                _chat, _message = string.split(" ", 2)
                _chat = message.chat.bakery.get_chat(_chat)
            rescue
                return "Error getting the chat. I am maybe not in that chat?"
            end
            text = Rainbow.new.rainbow_text(_message)


            _postawait = []

            while text.length > 0
                _build = ""
                _text = text.split("<font")
                _text = _text.drop(1)
                for i in _text
                    _part =  "<font#{i}"
                    if _build.length < 2200
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
            return "Done."
        end
    end

    def command_msend message, string
        if !@admins.include? message.user.downcase
            return "You do not have permission to use this command."
        else
            begin
                _chat, _message = string.split(" ", 2)
                _chat = message.chat.bakery.get_chat(_chat)
            rescue
                return "Error getting the chat. I am maybe not in that chat?"
            end
            message.chat.bakery.get_chat(_chat).chat_post(_message)
            return "Done."
        end
    end

    def command_whois message, string
        return message.chat.bakery.whois(string)
    end

    def command_seen message, string
        _user = string.downcase
        begin
            _message = message.chat.get_last_message(_user)
            return "[<b>#{_message.user}</b>] was last seen saying [<b>#{_message.content}</b>] in the room [<b>#{_message.chat.chat}</b>]"
        rescue
            return "I have not seen them around yet."
        end
    end

    def command_fart message, string
        return message.chat.fart
    end

    def command_e message, string
        if !@admins.include? message.user.downcase
            return "You do not have permission to use this command."
        else
            begin
                return eval(string)
            rescue StandardError => e
                return e
            end
        end
    end
end





