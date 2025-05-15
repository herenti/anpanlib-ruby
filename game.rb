require "json"
"""
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
                @response =  "You have not registered for the game yet. Use the command \"info register\" to get started. The command \"info\" will teach you about any game commands or items in the game. All game commands must have the word \"game\" in front of them, including any command prefix, unless using the terminal on your computer. Chatbot example: \"$game info register\". Terminal example: \"info register\"."
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
            pnum, mnum, snum, hnum = 10,10,10,100
            pnum *= user_class.statmult.physical
            mnum *= user_class.statmult.magic
            snum *= user_class.statmult.stealth
            hnum *= user_class.statmult.health
            homecity = user_class.homecity
            homevillage = Homevillages.new(homecity, race).name
            @user = User.new(500,
                             [],
                             @username,
                             0,
                             "gamestart",
                             homecity,
                             {"physical": pnum, "magic": mnum, "stealth": snum, "health": hnum},
                             0,
                             0,
                             homevillage,
                             user_class.name,
                             race,
                             nil,
                             @username
                            )
            @user_data[@username.downcase] = @user
            save_data
            @response =  "You have now begun your journey. You were born in a small villiage named #{@user.homevillage} near the city #{@user.homecity}. To begin your adventure you must make your way to the guild in #{@user.homecity}. You own an a magic encyclopedia passed down to you from your parents. It only shows you the information you need to see. It is used by the command \"info\" Use the command \"info commands\" to get started."
        else
            @response =  "You are already registered."
        end
    end

    def com_progress
        @response = Story.new(@user, "check").response
    end

    def com_wallet
        @response =  ("In your wallet you have: " + Money.new.calc_money(@user.money))
    end

    def com_location
        location = @user.location
        if location == "gamestart"
            village = Homevillages.new(@user.homecity, @user.race)
            @response = "You are in your home village, #{village.name}. It's description: #{village.description}"
            return
        end
        /for x, y in @gdata.locations
            loc =  y[:id]
            if loc == location
                desc = y[:desc]
                @response = "You are in ."
            end
        end/
    end

    def com_dice
        return "derp"
    end

    def com_travel
        /once traveled,
        event_res = Story.new(@user).response
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

#######################
#                     #
# GAME OBJECT CLASSES #
#                     #
#######################

class User

    attr_accessor :money, :weapons, :title, :progress, :location, :homecity, :stats, :level, :exp, :homevillage, :uclass, :race, :guild, :name

    def initialize money, weapons, title, progress, location, homecity, stats, level, exp, homevillage, uclass, race, guild, username
        @money = money
        @weapons = weapons
        @title = title
        @progress = progress
        @location = location
        @homecity = homecity
        @stats = NewObj.new(**stats)
        @level = level
        @exp = exp
        @homevillage = homevillage
        @uclass = uclass
        @race = race
        @guild = guild
        @name = username

    end
end

class Money

    attr_accessor

    def initialize
        @bronze = 1
        @brass = 100
        @silver = 1000
        @gold = 10000
    end

    def calc_money money
        list = []
        _money = money
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

        return (list.join(", ") + ".")
    end
end

class Races

    def initialize race
        case race
        when "druidim"
            @name = "druidim"
            @description = "description"
        when "harissif"
            @name = "harissif"
            @description = "description"
        when "human"
            @name = "druidim"
            @description = "description"
        end
    end
end

class Homevillages

    attr_accessor :name, :description

    def initialize homecity, race
        @race = race
        self.send(homecity.gsub(" ", "_"))
    end

    def aurendale
        case @race
        when "human"
            @name = "villagename"
            @description = "description"
        when "druidim"
            @name = "villagename"
            @description = "description"
        when "harissif"
            @name = "villagename"
            @description = "description"
        end
    end

    def flora_city
        case @race
        when "human"
            @name = "villagename"
            @description = "description"
        when "druidim"
            @name = "villagename"
            @description = "description"
        when "harissif"
            @name = "villagename"
            @description = "description"
        end
    end

    def lorienna
        case @race
        when "human"
            @name = "villagename"
            @description = "description"
        when "druidim"
            @name = "villagename"
            @description = "description"
        when "harissif"
            @name = "villagename"
            @description = "description"
        end
    end
end


class Story

    attr_accessor :response

    def initialize user, action
        @action = action
        _class = user.uclass
        @user = user
        @location = user.location
        @progress = user.progress
        self.send(_class)
    end

    def mage

        case @progress
        when 0
            if @location == "gamestart"
                @response = "You are in your home village, #{@user.homevillage}. It is time to leave behind life as your family has known it for generations and -travel- to the guild in #{@user.homecity}. once you leave your village you will never return..."
            elsif @location == "lorienna-guild"
                @response = "You have entered the Guild that you have set out to join. The clerk at the counter looks up at you, looking quite bored. \"Are you here to join the guild? He asks shyly. If you wish to join the guild, Say the command \"join guild\" and you will be signed up."
            else
                if @action == "check"
                    @response = "I have left my village and am now in #{@user.homecity}. My task is to -travel- to the guild here."

                end
            end
        end
    end

    def thief
        case @progress
        when 0
            if @location == "gamestart"
                @response = "You are in your home village, #{@user.homevillage}. It is time to leave behind life as your family has known it for generations and -travel- to the guild in #{@user.homecity}. once you leave your village you will never return..."
            elsif @location == "flora city-guild"
                @response = "You have entered the Guild that you have set out to join. The clerk at the counter looks up at you, looking quite bored. \"Are you here to join the guild? He asks shyly. If you wish to join the guild, Say the command \"join guild\" and you will be signed up."
            else
                if @action == "check"
                    @response = "I have left my village and am now in #{@user.homecity}. My task is to -travel- to the guild here."

                end
            end
        end
    end

    def warrior

        case @progress
        when 0
            if @location == "gamestart"
                @response = "You are in your home village, #{user.homevillage}. It is time to leave behind life as your family has known it for generations and -travel- to the guild in #{@user.homecity}. once you leave your village you will never return..."
            elsif @location == "aurendale-guild"
                @response = "You have entered the Guild that you have set out to join. The clerk at the counter looks up at you, looking quite bored. \"Are you here to join the guild? He asks shyly. If you wish to join the guild, Say the command \"join guild\" and you will be signed up."
            else
                if @action == "check"
                    @response = "I have left my village and am now in #{@user.homecity}. My task is to -travel- to the guild here."

                end
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

game = Game.new("herenti", "wallet", "")

puts game.response

sleep 1
