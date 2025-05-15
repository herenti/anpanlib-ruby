require "json"
"""
MIGHT NOT BE FUNCTIONAL IF IN PROGRESS. I UPLOAD OFTEN TO BACK UP.
todo:
can only travel to nearby location before traveling to further location. map must progress in a line. - buy teleport scroll,
when classes level up they get more points to affiliated skills
starting villiage does not actually exist on the map. once players travel to the homecity they can not go back.
statmults by race affinity, levelup
each homecity has a homevillage by race
migrate from gamedata class to seperate classes for things.
make user class. should be easy and work well. send args to class to make the user
each class has its own story.
area random enemy encounters less by stealth. hit chance by stealth. attack speed by agility. put in agility in class info.
check event on travel
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
                _stats = NewObj.new(**y["stats"])
                y["stats"] = _stats
                _user = NewObj.new(**y)
                userdata[x] = _user
            end
        end

        return userdata
    end

    def save_data
        for x, y in @user_data
            obj_hash = Hash[y.instance_variables.map { |var| [var.to_s[1..-1], y.instance_variable_get(var)] } ]
            stats_hash = Hash[y.stats.instance_variables.map { |var| [var.to_s[1..-1], y.stats.instance_variable_get(var)] } ]
            obj_hash["stats"] = stats_hash
            @user_data[x] = obj_hash
        end
        File.write('gamedata.txt', @user_data.to_json)
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
                @response =  "You have not registered for the game yet. Use the command \"register\". Use the command \"info\" for any questions once registered. All game commands must have the word \"game\" in front of them, including any command prefix, unless using the terminal on your computer. Chatbot example: \"$game register calssname racename gender\". Terminal example \"register classname racename gender\"."
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
                "money": 500,
                "weapons": ["unarmed"],
                "title": "",
                "progress": 0,
                "location": "gamestart",
                "homecity": homecity,
                "stats": NewObj.new(**{"physical": pnum, "magic": mnum, "stealth": snum, "health": hnum}),
                "level": 0,
                "exp": 0,
                "homevillage": homevillage[0],
                "class": user_class.name,
                "race": race,
                "name": @username,
                "guild": nil

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
        @response =  ("In your wallet you have: " + Money.new(@user.money).calc)
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
        /once traveled,
        event_res = Events.new(@user).response
        if event_res.length > 0
            @response = event_res
            return
        /
    end

    def com_join
        if args == "guild"
            if @user.guild == nil
                if @user.progress == 0
                    if @user.location == (@user.homecity+"-guild")
                        @user.guild = guilds[@user.homecity]
                        @user.progres = 1
                        @response = "Congradulations, you have joined the local guild. Your next goal is to buy weapons, armor, and any items before getting your first quest from the guild. It is dangerous out in the wild, so a quest is a good place to start."
                        save_data
                        return
                    end
                end
            end
        end
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

class User

    attr_accessor :money, :weapons, :title, :progress, :location, :homecity, :stats, :level, :exp, :homevillage, :uclass, :race, :name, :guild

    def initialize money, weapons, title, progress, location, homecity, stats, level, exp, homevillage, uclass, race, guild, username
        @money = money
        @weapons = weapons
        @title = title
        @progress = progress
        @location = location
        @homecity = homecity
        @stats = NewObj(**stats)
        @level = level
        @exp = exp
        @homevillage = homevillage
        @uclass = uclass
        @race = race,
        @guild = nil,
        @name = username

    end
end

class Money

    attr_accessor :calc

    def initialize money
        @bronze = 1
        @brass = 100
        @silver = 1000
        @gold = 10000
        @money = money
        calc_money
    end

    def calc_money
        list = []
        _money = @money
        if _money > @gold
            _gold = _money / @gold
            _money -= @gold * _gold
            if _gold > 1 then list.append("#{_gold.to_s} gold coins") else list.append("#{_gold.to_s} gold coin") end
        end
        if _money > @silver
            _silver = _money / @silver
            _money -= @silver * _silver
            if _silver > 1 then list.append("#{_silver.to_s} silver coins") else list.append("#{_silver.to_s} silver coin") end
        end
        if _money > @brass
            _brass = _money / @brass
            _money -= @brass * _brass
            if _brass > 1 then list.append("#{_brass.to_s} brass coins") else list.append("#{_brass.to_s} brass coin") end
        end
        if _money > @bronze
            _bronze = _money
            if _bronze > 1 then list.append("#{_bronze.to_s} bronze coins") else list.append("#{_bronze.to_s} bronze coin") end
        end

        @calc =  string = (list.join(", ") + ".")
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

class Events

    attr_accessor :event, :story

    def initialize user
        _class = user.uclass
        @user = user
        self.send(_class)
        @response = ""
        @location = user.location
        @progress = user.progress
    end

    def mage

        case @progress
        when 0
            if @location == "lorienna-guild"
                @response = "You have entered the Guild that you have set out to join. The clerk at the counter looks up at you, looking quite bored. \"Are you here to join the guild? He asks shyly. If you wish to join the guild, Say the command \"join guild\" and you will be signed up."
            end


        end
    end
end



class Mage

    attr_accessor :homecity, :raceaff, :statmult, :raceunaff, :name, :special_abilities, :waff, :wunaff

    def initialize
        @name = "mage"
        @homecity = "lorienna"
        @raceaff = "druidim"
        @statmult = NewObj.new(**{"physical": 0.6, "magic": 1.8, "stealth": 1.2, "health": 1.1})
        @raceunaff = "human"
        @waff = "magic"
        @wunaff = "mele"
    end
end

class Warrior

    attr_accessor :homecity, :raceaff, :statmult, :raceunaff, :name, :special_abilities, :waff, :wunaff

    def initialize
        @name = "warrior"
        @homecity = "aurendale"
        @raceaff = "harissif"
        @statmult = NewObj.new(**{"physical": 1.8, "magic": 0.7, "stealth": 0.8, "health": 1.4})
        @raceunaff = "druidim"
        @waff = "mele"
        @wunaff = "magic"

    end
end

class Thief

    attr_accessor :homecity, :raceaff, :statmult, :raceunaff, :name, :special_abilities, :waff, :wunaff

    def initialize
        @name = "thief"
        @homecity = "flora city"
        @raceaff = "human"
        @statmult = NewObj.new(**{"physical": 1.2, "magic": 0.9, "stealth": 1.8, "health": 0.8})
        @raceunaff = "harissif"
        @waff = "none"
        @wunaff = "nome"
    end
end


class Weapons

    attr_accessor :unarmed, :rusty_sword, :flimsy_bow, :training_staff, :pocket_knife

    def initialize
        @unarmed = NewObj.new(**{
                                 "wtype": "dagger",
                                 "type": "mele",
                                 "damage": 1,
                                 "ammo": nil,
                                 "speed": 1
                                })

        @rusty_sword = NewObj.new(**{
                                 "wtype": "sword",
                                 "type": "mele",
                                 "damage": 5,
                                 "ammo": nil,
                                 "speed": 3
                                })

        @flimsy_bow = NewObj.new(**{
                                     "wtype": "bow",
                                     "type": "mele",
                                     "damage": 3,
                                     "ammo": nil,
                                     "speed": 5
                                    })

        @rusty_sword = NewObj.new(**{
                                     "wtype": "sword",
                                     "type": "mele",
                                     "damage": 1,
                                     "ammo": nil,
                                     "speed": 3
                                    })




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

game = Game.new("herenti", "wallet", "")

puts game.response

sleep 1
