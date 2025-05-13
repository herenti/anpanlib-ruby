require "json"
"""
todo:
can only travel to nearby location before traveling to further location. map must progress in a line. - buy teleport scroll,
when classes level up they get more points to affiliated skills
starting villiage does not actually exist on the map. once players travel to the homecity they can not go back.
statmults by race affinity, levelup
each homecity has a homevillage by race
continue to migrate from gamedata class to seperate classes for things.
"""

class Game

    attr_accessor :user_data, :response, :user

    def initialize username, command, args
        @username = username
        @command = ("com_"+command.downcase)
        @args = args.downcase
        #@commands = Commands.new
        @classes = [Thief.new, Mage.new, Warrior.new]
        @user_data = load_data
        if @user_data.keys.include? @username.downcase
            @registered = true
        else
            @registered = false
        end
        if @registered
            @user = @user_data[@username]
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
                for i in @classes
                    if i.name = y["class"]
                        _class = i
                        break
                    end
                end
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
                      "homevillage": y["homevillage"],
                      "class": _class,
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
                        "homevillage": y.homevillage,
                        "class": y.class.name,
                        "race": y.race
                    }
            data[x] = _tohash
        end
        File.write('gamedata.txt', data.to_json)
    end

    def command_call
        if @registered
            if self.respond_to?(@command)
                self.send(@command)
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
            for i in @classes
                if i.name = _class
                    user_class = i
                    break
                end
            end
            races = @gdata.races
            pnum, mnum, snum, hnum = 10,10,10,100
            pnum *= user_class.statmult.physical
            mnum *= user_class.statmult.magic
            snum *= user_class.statmult.stealth
            hnum *= user_class.statmult.health
            homecity = user_class.homecity
            homevillage = @gdata.homevillages[sym(homecity)][sym(race)]
            @user = NewObj.new(**{
                "money": 1000,
                "weapons": ["unarmed"],
                "title": "",
                "progress": 0,
                "location": "gamestart",
                "homecity": homecity,
                "stats": NewObj.new(**{"physical": pnum, "magic": mnum, "stealth": snum, "health": hnum}),
                "level": 0,
                "exp": 0,
                "homevillage": homevillage[0],
                "class": user_class,
                "race": race

            })
            @user_data[@username.downcase] = @user
            save_data
            @response =  "You have now begun your journey. You were born in a small villiage named #{@user.homevillage} near the city #{@user.homecity}. To begin your adventure you must make your way to the guild in #{@user.homecity}. You own an a magic encyclopedia passed down to you from your ancestors. It only shows you the information you need to see. Use the command \"info\" to get started. All game commands must have the word \"game\" in front of them, including any command prefix. Exampe: \"$game register\"."
        else
            @response =  "You are already registered."
        end
    end

    def com_progress
        message = @gdata.progress_message
        message = message[sym(@user.progress.to_s)]
        @response =  message.gsub("<m>", @user.money.to_s).gsub("<h>", @user.homecity)
    end

    def com_wallet
        @response =  "You have #{@user.money.to_s} gold in your coin purse."
    end

    def com_location
        location = @user.location
        if location == "gamestart"
            desc = @gdata.homevillages[sym(@user.homecity)][sym(@user.race)][1]
            @response = "You are in your home village, #{@user.homevillage}. It's description: #{desc}"
            return
        end
        for x, y in @gdata.locations
            loc =  y[:id]
            if loc == location
                desc = y[:desc]
                @response = "You are in #{x}. It's description: #{desc}."
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

        for key, value in args
            singleton_class.class_eval { attr_accessor "#{key}" }
            send("#{key}=", value)
        end
    end
end

class Gamedata

    attr_accessor :progress_message, :homevillages, :hometowns, :locations, :races

    def initialize
        @progress_message = {
            "0": "You have just started on your journey to be a hero. You are kind of broke though, as you only have <m> gold, you have not had your first level up, but hopefully things work out well. Your job is to travel to the closest town, <h>, and join the guild.",
            "1": "Congradulations, you have joined the local guild. Your next goal is to buy weapons, armor, and any items before getting your first quest from the guild. It is dangerous out in the wild, so a quest is a good place to start."
        }
        @locations = {"aurendale":
                      {
                        "nearby":[], "desc": "A grassland city with a large farming economy. It has a guild, an item shop, and a combat shop. There is a famed training ground for the greatest warriors in the country."
                      },
                      "lorienna":
                     {
                      "nearby":[], "desc": "A woodland city with people gifted in magic. It has a guild, an item shop, and a combat shop. The magic university is located here."
                      },
                      "flora city":
                     {
                      "nearby":[], "desc": "A coastal city full of year round flowers. Mostly warm weather and a good balance between rainy and sunny weather. It has a guild, an item shop, and a combat shop. Despite its beautiful appearance, on the outskirts of the city there is a slum that is teeming with theives and a thieves guild."
                     }
                     }
        @homevillages = {
            "aurendale": {
                          "human": ["villagename","description"],
                          "druidim": ["villagename","description"],
                          "harissif": ["villagename","description"],

                        },
            "lorienna": {
                          "human": ["villagename","description"],
                          "druidim": ["villagename","description"],
                          "harissif": ["villagename","description"],

                          },
            "flora city": {
                          "human": ["florahumanvillagename","descriptionderp"],
                          "druidim": ["villagename","description"],
                          "harissif": ["villagename","description"],

                          }
                        }
        @races = {"druidim": "description", "harissif": "description", "human": "description"}

    end
end

class Mage

    attr_accessor :homecity, :raceaff, :statmult, :raceunaff, :name, :special_abilities

    def initialize
        @name = "mage"
        @homecity = "lorienna"
        @raceaff = "druidim"
        @statmult = NewObj.new(**{"physical": 0.6, "magic": 1.8, "stealth": 1.2, "health": 1.1})
        @raceunaff = "human"
    end
end

class Warrior

    attr_accessor :homecity, :raceaff, :statmult, :raceunaff, :name, :special_abilities

    def initialize
        @name = "warrior"
        @homecity = "aurendale"
        @raceaff = "druidim"
        @statmult = NewObj.new(**{"physical": 1.8, "magic": 0.7, "stealth": 0.8, "health": 1.4})
        @raceunaff = "druidim"
    end
end

class Thief

    attr_accessor :homecity, :raceaff, :statmult, :raceunaff, :name, :special_abilities

    def initialize
        @name = "thief"
        @homecity = "flora city"
        @raceaff = "human"
        @statmult = NewObj.new(**{"physical": 1.2, "magic": 0.9, "stealth": 1.8, "health": 0.8})
        @raceunaff = "harissif"
    end
end


def sym x
    return :"#{x}"
end

game = Game.new("herenti", "register", "thief human")

puts game.response

sleep 1

game = Game.new("herenti", "location", "")

puts game.response

sleep 1

game = Game.new("herenti", "progress", "")

puts game.response

sleep 1

puts game.user.class.name
