# encoding: utf-8

module Excession

  module Parser
    
    def self.parse(str)
      CssTransform.new.apply(CssParser.new.parse(str))
    end # def self.parse
  

    
    class CssTransform < Parslet::Transform
      rule(:comment => simple(:content)){CommentNode.new(content)}
      rule(:whitespace => simple(:content)){WhitespaceNode.new(content)}
      rule(:selectors => simple(:selectors)){SelectorsNode.new(selectors)}
      rule(:ruleset => simple(:ruleset)){RulesetNode.new(ruleset)}
      rule(:children => sequence(:children)){CssFile.new(children)}
    end


    class CssFile < Struct.new(:children)

    end
  

    class CommentNode < Struct.new(:content)
    end

    class WhitespaceNode < Struct.new(:content)
    end

    class SelectorsNode < Struct.new(:selectors)
    end

    class RulesetNode < Struct.new(:selectors, :children)
    end


  end # class Parser


  



end # module Excession
