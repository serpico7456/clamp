require 'spec_helper'

describe Clamp::Command do

  extend CommandFactory
  include OutputCapture

  describe "with subcommands" do

    given_command "flipflop" do

      subcommand "flip", "flip it" do
        def execute
          puts "FLIPPED"
        end
      end

      subcommand "flop", "flop it\nfor extra flop" do
        def execute
          puts "FLOPPED"
        end
      end

    end

    it "delegates to sub-commands" do

      @command.run(["flip"])
      stdout.should =~ /FLIPPED/

      @command.run(["flop"])
      stdout.should =~ /FLOPPED/

    end

    describe "#help" do
      
      it "lists subcommands" do
        @help = @command.help
        @help.should =~ /Subcommands:/
        @help.should =~ /flip +flip it/
        @help.should =~ /flop +flop it/
      end
      
      it "handles new lines in subcommand descriptions" do
        @help = @command.help        
        @help.should =~ /flop +flop it\n +for extra flop/
      end
      
    end
    
  end

  describe "with an aliased subcommand" do
    
    given_command "blah" do

      subcommand ["say", "talk"], "Say something" do
        
        parameter "WORD ...", "stuff to say"
        
        def execute
          puts word_list
        end
        
      end
      
    end
    
    it "responds to both aliases" do

      @command.run(["say", "boo"])
      stdout.should =~ /boo/

      @command.run(["talk", "jive"])
      stdout.should =~ /jive/

    end
    
    describe "#help" do 

      it "lists all aliases" do
        @help = @command.help
        @help.should =~ /say, talk .* Say something/
      end

    end
    
  end
  
  describe "with nested subcommands" do

    given_command "fubar" do

      subcommand "foo", "Foo!" do

        subcommand "bar", "Baaaa!" do
          def execute
            puts "FUBAR"
          end
        end

      end

    end

    it "delegates multiple levels" do
      @command.run(["foo", "bar"])
      stdout.should =~ /FUBAR/
    end

  end
  
  describe "with a default subcommand" do
    
    given_command "admin" do

      default_subcommand "status", "Show status" do

        def execute
          puts "All good!"
        end

      end

    end

    it "delegates multiple levels" do
      @command.run([])
      stdout.should =~ /All good/
    end
    
  end
  
  describe "each subcommand" do

    before do

      speed_options = Module.new do
        extend Clamp::Option::Declaration
        option "--speed", "SPEED", "how fast", :default => "slowly"
      end

      @command_class = Class.new(Clamp::Command) do

        option "--direction", "DIR", "which way", :default => "home"

        include speed_options
        
        subcommand "move", "move in the appointed direction" do

          def execute
            motion = context[:motion] || "walking"
            puts "#{motion} #{direction} #{speed}"
          end

        end

      end

      @command = @command_class.new("go")

    end

    it "accepts options defined in superclass (specified after the subcommand)" do
      @command.run(["move", "--direction", "north"])
      stdout.should =~ /walking north/
    end

    it "accepts options defined in superclass (specified before the subcommand)" do
      @command.run(["--direction", "north", "move"])
      stdout.should =~ /walking north/
    end

    it "accepts options defined in included modules" do
      @command.run(["move", "--speed", "very quickly"])
      stdout.should =~ /walking home very quickly/
    end

    it "has access to command context" do
      @command = @command_class.new("go", :motion => "wandering")
      @command.run(["move"])
      stdout.should =~ /wandering home/
    end

  end

end
