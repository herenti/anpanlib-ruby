require_relative "genrainbow" #this code can be found in the "extra-stuff" repository. i do not own the rainbow code.
require_relative "translate"


class Commands

    def initialize chat = nil, bakery=nil, user=nil
        @chat = chat
        @bakery = bakery
        @user = user
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

    def command_droll message, string
        banned = 'abcefgijmnopqrstuvwxyz'
        for i in string.split("")
            if banned.include? i
                return "that is not a valid opteration"
            end
        end
        operations = string.split(" ")
        result = 0
        result = result.to_f
        for x in operations
            if x.include? "d"
                x = x.split("d")
                _num, sides = x[0], x[1]
                operator = _num[0]
                _num = _num.gsub(operator, "")
                if sides.include? "kl"
                    koperator = "kl"
                elsif sides.include? "kh"
                    koperator = "kh"
                else
                    koperator = nil
                end
                sides = sides.gsub("kl", "").gsub("kh", "").to_i
                if koperator == "kh" or koperator == "kl"
                    list = []
                    for i in (1.._num.to_i).to_a
                        _result = rand (1..sides.to_i)
                        list.append(_result)
                    end
                    if koperator == "kl"
                        keep = list.min
                    elsif koperator == "kh"
                        keep = list.max
                    end
                    if operator == "+"
                        result += keep
                    elsif operator == "-"
                        result -= keep
                    elsif operator == "*"
                        result *= keep
                    elsif operator == "/"
                        result /= keep
                    end
                else
                    if operator == "+"
                        result += rand (_num.to_i..(_num.to_i*sides.to_i))
                    elsif operator == "-"
                        result -= rand (_num.to_i..(_num.to_i*sides.to_i))
                    elsif operator == "*"
                        result *= rand (_num.to_i..(_num.to_i*sides.to_i))
                    elsif operator == "-"
                        result /= rand (_num.to_i..(_num.to_i*sides.to_i))
                    end
                end
            else
                if x.include? "+"
                    result += x.gsub("+", "").to_i
                elsif x.include? "-"
                    result -= x.gsub("-", "").to_i
                elsif x.include? "*"
                    result *= x.gsub("*", "").to_i
                elsif x.include? "/"
                    result /= x.gsub("/", "").to_i
                end
            end
        end
        return result
    end

    def command_rsend message, string
        if !@admins.include? @user.downcase
            return "You do not have permission to use this command."
        else
            begin
                _chat, _message = string.split(" ", 2)
                _chat = @bakery.get_chat(_chat)
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
        if !@admins.include? @user.downcase
            return "You do not have permission to use this command."
        else
            _chat, _message = string.split(" ", 2)
            begin
                @bakery.get_chat(_chat).chat_post(_message)
            rescue
                return "Error getting the chat. I am maybe not in that chat?"
            end
            return "Done."
        end
    end

    def command_whois message, string
        return @bakery.whois(string)
    end

    def command_seen message, string
        _user = string.downcase
        begin
            _message = @chat.get_last_message(_user)
            return "[<b>#{_message.user}</b>] was last seen saying [<b>#{_message.content}</b>] in the room [<b>#{_message.chat.chat}</b>]"
        rescue
            return "I have not seen them around yet."
        end
    end

    def command_fart message, string
        return @chat.fart
    end

    def command_e message, string
        if !@admins.include? @user.downcase
            return "You do not have permission to use this command."
        else
            begin
                return eval(string)
            rescue StandardError => e
                return e
            end
        end
    end

    def command_yt message, string
        begin
            _string = URI::Parser.new.escape(string)
            uri = "https://www.googleapis.com/youtube/v3/search?q=#{_string}&key=&type=video&maxResults=1&part=snippet"
            res = URI.open(uri).read
            parsed = JSON.parse(res)
            _id = parsed["items"][0]["id"]["videoId"]
            _title = parsed["items"][0]["snippet"]["title"]
            return ("\r\rVideo title [<b>#{_title}</b>]\r\rhttps://www.youtube.com/watch?v=#{_id}")
        rescue
            return "There was an error in the search"
        end

    end

    def command_youtube message, string
        return yt message string
    end

    def command_shutdown message, string
        @chat.chat_post("shutting down")
        sleep 1
        @bakery.anpan_is_tasty = false
    end
end





