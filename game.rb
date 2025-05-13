require "json"
"""
todo:
can only travel to nearby before progressing - buy teleport scroll,
when classes level up they get more points to affiliated skills
starting villiage does not actually exist in game data, the only place users can travel at 0 progress is their home city, and they can never go back
statmults by race affinity
"""

class Game

    attr_accessor :user_data, :response

    def initialize username, command, args
        @username = username
        @command = ("com_"+command.downcase)
        @args = args.downcase
        #@commands = Commands.new
        @user_data = load_data
        if @user_data.keys.include? @username.downcase
            @registered = true
        else
            @registered = false
        end
        @gdata = Gamedata.new
        command_call
    end

    def load_data
        userdata = {}
        data = File.read("gamedata.txt")
        if data.length > 0
            data = JSON.parse(data)
            for x, y in data
                _user = NewObj.new(**{
                      "money":  y["money"],
                      "weapons": y["weapons"],
                      "title": y["title"],
                      "progress": y["progress"],
                      "location": y["location"],
                      "homecity": y["homecity"],
                      "stats": NewObj.new(**y["stats"]),
                      "level": y["level"],
                      "exp": y["exp"],
                      "class": y["class"],
                      "race": y["race"]
                     })
                userdata[x] = _user
            end
        end

        return userdata
    end

    def save_data
        data = {}
        for x, y in user_data
            _tohash = {
                        "money": y.money,
                        "weapons": y.weapons,
                        "title": y.title,
                        "progress": y.progress,
                        "location": y.location,
                        "homecity": y.homecity,
                        "stats": {"physical": y.stats.physical, "magic": y.stats.magic, "stealth": y.stats.stealth, "health": y.stats.health},
                        "level": y.level,
                        "exp": y.exp,
                        "class": y.class,
                        "race": y.race
                    }
            data[x] = _tohash
        end
        File.write('gamedata.txt', data.to_json)
    end

    def command_call
        if @registered
            if self.respond_to?(@command)
                @response =  self.send(@command)
            else
                @response = "That is not a valid command."
            end
        else
            if @command == "com_register"
                com_register
            else
                @response =  "You have not registered for the game yet. Use the command \"register\". Use the command \"info\" for any questions. All game commands must have the word \"game\" in front of them, including any command prefix. Exampe: \"$game register\"."
            end
        end
    end

    ############
    #          #
    # COMMANDS #
    #          #
    ############

    def com_register
        if !@registered
            _class, race = @args.split(" ")[0], @args.split(" ")[1]
            classes = @gdata.classes
            races = @gdata.races
            pnum, mnum, snum, hnum = 10,10,10,100
            for x, y in classes.dig _class.to_sym, :statmult
                x = x.to_s
                y = y.to_f
                case x
                when "pysical"
                    pnum *= y
                when "magic"
                    mnum *= y
                when "stealth"
                    snum *= y
                when "health"
                    hnum *= y
                end
            end
            homecity = classes.dig _class.to_sym, :homecity
            homecity = homecity.to_s
            location = @gdata.locations.dig homecity.to_sym, :id
            location = location.to_i
            @user = NewObj.new(**{
                "money": 1000,
                "weapons": ["unarmed"],
                "title": "",
                "progress": 0,
                "location": location,
                "homecity": homecity,
                "stats": NewObj.new(**{"physical": pnum, "magic": mnum, "stealth": snum, "health": hnum}),
                "level": 0,
                "exp": 0,
                "class": _class,
                "race": race
            })
            @user_data[@username.downcase] = @user
            save_data
            @response =  "You have now begun your journey. You were born in a small villiage named asdfk near the city #{@user.homecity}. To begin your adventure you must make your way to the guild. You own an a magic encyclopedia passed down to you from your ancestors. It only shows you the information you need to see. Use the command \"info thingtogetinfoon\". All game commands must have the word \"game\" in front of them, including any command prefix. Exampe: \"$game register\"."
        else
            @response =  "You are already registered."
        end
    end

    def com_progress
        message = @gdata.progress_message
        message = message[@user.progress.to_s]
        @response =  message
    end

    def com_wallet
        @response =  "You have #{@user.money} gold in your coin purse."
    end

    def com_location
        location = @user.location
        for x in @gdata.locations[location]
            if x["id"] == location
                @response =  "You are in #{location}. Here is it's description: #{x["desc"]}"
            end
        end
    end

    def com_dice
        return "derp"
    end

    def com_travel
        #position = @user_data
    end


end


class NewObj

    def initialize(**args)
        @args = args
        to_set()
    end

    def set_attr(key, value)
        singleton_class.class_eval { attr_accessor "#{key}" }
        send("#{key}=", value)
    end

    def to_set
        for x, y in @args
            set_attr(x, y)
        end
    end

end

class Gamedata

    attr_accessor :progress_message, :hometowns, :locations, :classes, :races

    def initialize
        @progress_message = {
            "0": "You have just started on your journey to be a hero. You are kind of broke though, you only have <m> gold, you have not had your first level up, but hopefully things work out well. Your job is to travel to the closest town, <h> and join the guild.",
            "1": "Congradulations, you have joined the local guild. Your next goal is to buy weapons, armor, and any items before getting your first quest from the guild. It is dangerous out in the wild, so a quest is a good place to start."
        }
        @locations = {"Aurendale":
                      {
                       "id": 1, "nearby":[], "desc": "A grassland city with a large farming economy. It has a guild, an item shop, and a combat shop. There is a famed training ground for the greatest warriors here."
                      },
                      "Lorienna":
                     {
                      "id": 2, "nearby":[], "desc": "A woodland city with people gifted in magic. It has a guild, an item shop, and a combat shop. The magic university is located here."
                      },
                      "flora city":
                     {
                      "id": 3, "nearby":[], "desc": "A coastal city full of year round flowers. Mostly warm weather and a good balance between rainy and sunny weather. It has a guild, an item shop, and a combat shop. Despite its beautiful appearance, on the outskirts of the city there is a slum that is teeming with theives and a thieves guild."
                     }
                     }
        @classes = {
            "mage": {
                        "homecity": "Lorienna",
                        "raceaff": "druidim",
                        "statmult": {"physical": 0.6, "magic": 1.8, "stealth": 1.2, "health": 1.1},
                       "raceunaff": "harissif"
                       },
            "warrior": {
                        "homecity": "Aurendale",
                        "raceaff": "harissif",
                        "statmult": {"physical": 1.8, "magic": 0.7, "stealth": 0.8, "health": 1.4},
                        "raceunaff": "druidim"
                       },
            "thief": {
                        "homecity": "flora city",
                        "raceaff": "human",
                        "statmult": {"physical": 1.1, "magic": 1, "stealth": 1.8, "health": 0.8},
                       "raceunaff": "harissif"
                       }
        }
        @races = {"druidim": "description", "harissif": "description", "human": "description"}

    end
end

game = Game.new("herenti", "register", "thief human")

puts game.response
puts game.user_data["herenti"].homecity
