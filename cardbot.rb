#!/usr/bin/env ruby
 
#Requires for different parts of the bot
require 'rubygems'
require 'cinch'
require 'yaml'
require 'nokogiri'
require 'open-uri'

#create the bot object
bot = Cinch::Bot.new do
	configure do |c|
		#IRC configuration
		c.server = "Limestone.TX.US.GameSurge.net"
		c.channels = ["#mtg-reddit"]
		c.user = "Cardbot"
		c.nick = "Cardbot"
		c.port = "6667"
	end

	#Load yml up here so we don't have multiple instances in memory.
	yml = YAML.load_file 'db/oracle.yml'	

	#Command to reparse the oracleDB in case of new sets or updated oracle or whatever
	on :message, /^!reparseoracle/ do |m|
		#Initialize some stuff, the hash we store data in, the counter to tell if it's a name or not, and load up the existing yaml for later use. 
		h = {}
		counter = 0
		File.open("db/oracle.txt","r") do |f|
		       	while l = f.gets
				if l =~ /^$/
				#A blank line means the end of a card, parse it out into yaml and clear the hash for use again.
        		               	counter = 0
               	        		yml[h["name"]] = h
		               	else
                		       	if counter == 0
                        		       	h = { "name" => l.gsub("\n",""), "data" => {}}
                                		counter += 1
		       	                else
        		       	                h["data"]["d#{counter}"] = l.gsub("\n","")
                		       	        counter +=1
                        		end

		       	        end
			end
		end
		#We Want to write at the end because it will be faster then re-opening the file handler constantly. 
		File.open("db/oracle.yml","w") do |y|
			y.write(yml.to_yaml)
		end
		m.reply "Reparsed Oracle DB"
		yml = YAML.load_file 'db/oracle.yml'
	end




	on :message, /^!help ?(.*)/ do |m,q|
		if q.downcase == "price"
			m.reply "#{m.user.nick}: Looks up TCGPlayer prices of a card. Usage: !price <card>."
		elsif q.downcase == "card"
			m.reply "#{m.user.nick}: Looks up the oracle of a card. Usage: !card <card>."
		else
			m.reply "#{m.user.nick}: Current commands: !card, !price. Use !help <command> for more information"
		end
	end


	#Oracle Lookup
	on :message, /^!card ?(.*)/ do |m,q|
		        if q.empty?
		                m.reply "You need to specify a card to search for. Usage: !card <card>"
		        else
		                yml.each do |k|
                	        if k[1]["name"].downcase =~ /^#{q.downcase}$/
                        	        v = ""
                                	k[1]["data"].to_enum.with_index(1).each do |(key,value),index|
                                        	v = "#{v}" + "| #{value} "
	                                        if k[1]["data"].size == index
        	                                        m.reply "#{m.user.nick}: #{k[1]["name"]} #{v}"
                	                        end

                        	        end
	                        end
        	        end
	        end
	end

	#Price Lookup using tcgplayer
	on :message, /^!price ?(.*)/ do |m,q|
		if q.empty?
			m.reply "You need to specify a card to search for. Usage: !price <card>"
		else
			
			a = ""
			q.split.each do |u|
			        if a.empty?
			                a = "#{u}"
		        	else
		                	a = "#{a}%20#{u}"
			        end
			end

			page = Nokogiri::HTML(open("http://magic.tcgplayer.com/db/magic_single_card.asp?cn=#{a}"))
			p = Array.new
			page.css('td.default_8 center b').each_with_index do |price,i|
			        p[i] = price.text
			end
			m.reply "#{m.user.nick}: #{q} Prices: High - #{p[0]} | Mid - #{p[1]} | Low - #{p[2]} | http://magic.tcgplayer.com/db/magic_single_card.asp?cn=#{a}"
		end
	end

#End Bot and Start it
end
bot.start
	

