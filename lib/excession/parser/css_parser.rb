# encoding: utf-8
require 'parslet'

module Excession

  module Parser
    

    class CssParser < Parslet::Parser
      def initialize(strict=false)
        @strict=strict
        super()
      end

      rule(:h){  match["0-9a-fA-F"] }
      rule(:nonascii){ match["\200-\377".force_encoding("BINARY")] }
      rule(:unicode){ 
        str("\\") >> h.repeat(1,6) >> (str("\r\n") | match[" \t\r\n\f"]).maybe 
      }
      rule(:escape){
       (unicode | (str("\\\\") >> match["\r\n\f0-9a-fA-F"].absnt? >> any))
      }
      rule(:nmstart){ match["_a-zA-Z"] | nonascii | escape }
      rule(:nmchar){ match["_a-zA-Z0-9-"] | nonascii | escape }
      rule(:nl){ str("\n") | str("\r\n") | str("\r") | str("\f") }
      rule(:dqstring_contents){
        (
         (match["\n\r\f\""].absnt? >> any) |
         (str("\\\\") >> nl) |
         escape
        ).repeat
      }
      rule(:sqstring_contents){
        (
         (match["\n\r\f'"].absnt? >> any) |
         (str("\\\\") >> nl) |
         escape
        ).repeat
      }
      rule(:string1){ str('"') >> dqstring_contents  >>  str('"') }
      rule(:string2){ str("'") >> sqstring_contents >>   str("'") }
      rule(:badstring1){ str('"') >> dqstring_contents >> str("\\").maybe }
      rule(:badstring2){ str("'") >> sqstring_contents >> str("\\").maybe }
      rule(:badcomment1){ 
        str("/*") >> 
        (match["*"].absnt? >> any).repeat >>
        str("*").repeat(1) >>
        (
         match["/*"].absnt? >> any >>
         (match["*"].absnt? >> any).repeat >>
         str("*").repeat(1)
         ).repeat
      }
      rule(:badcomment2){
        str("/*") >>
        (match["*"].absnt? >> any).repeat >>
        (
         str("*").repeat(1) >>
         match["/*"].absnt? >> any >>
         (match["*"].absnt? >> any).repeat
         ).repeat
      }


      # These are used to get the JS in an expression() declaration.
      # Since we don't care much for parsing JS here, I'm just using
      # the rule that valid JS must have balanced parens, and ignore
      # unbalanced parens in comments and strings. For now.
      # Thanks, IE.
      rule(:js_chars){ (match["()"].absnt? >> any).repeat(1) }
      rule(:js_bracketed){ str("(") >> js_balancing.maybe >> str(")") }
      rule(:js_balancing){ ( js_chars | js_bracketed ).repeat(1) }
      

      rule(:s){ match[" \t\r\n\f"].repeat(1) }
      rule(:w){ s.repeat(0) }

      rule(:baduri1){
        str("url(") >> w >> 
        (
         match['!#$%&*-\[\]-~'] |
         nonascii |
         escape
         ).repeat >>
        w
      }

      rule(:string){ string1 | string2  }
      
      rule(:baduri2){ str("url(") >> w >> string >> w  }

      rule(:badstring){ badstring1 | badstring2 }
      rule(:baduri3){ str("url(") >> w >> badstring }


      rule(:comment){ 
        str("/*") >>
        (
         match["*"].absnt? >> any
         ).repeat >>
        str("*").repeat(1) >> 
        (
         match["*/"].absnt? >> any >>
         (match["*"].absnt? >> any).repeat >>
         str("*").repeat(1)
         ).repeat >>
        str("/")
      }
      

      rule(:ident){
        str("-").maybe >> nmstart >> nmchar.repeat
      }

      rule(:name){ nmchar.repeat(1) }
      rule(:num){ 
        (
         match["0-9"].repeat(0) >> 
         str(".") >> 
         match["0-9"].repeat(1)
         ) |
        match["0-9"].repeat(1) 
      }


      rule(:badcomment){ badcomment1 | badcomment2 }
      
      rule(:baduri){ baduri2 | baduri3 | baduri1 }

      rule(:url){
        (
         match['!#$%&*-~'] |
         nonascii |
         escape
         ).repeat
      }
      
      # Case insensitive character match with escaped character codes.
      #
      # TODO: The CSS2.1 spec allows all letters apart from
      # a,c,d and e to be specified like "\g". This is not supported
      # here.
      def cimatch(char)
        upper = char.upcase.force_encoding("BINARY")
        lower = char.downcase.force_encoding("BINARY")
        return match["#{upper}#{lower}"] | 
          ( str("\\") >> 
            str("0").repeat(0,4) >>
            (str(upper[0].ord.to_s(16)) | str(lower[0].ord.to_s(16))) >>
            (str("\r\n") | match[" \t\r\n\f"]).maybe )
      end
    

      def cimatch_word(word)
        word.each_char.map{|c| self.cimatch(c)}.reduce(:>>)
      end


      rule(:sym_comment){ comment.as(:comment) }
      # NB: Deviation. Comments are ignored in the 2.1 grammar, but I
      # want to preserve them. I've made the S symbol cover comments
      # as well.
      rule(:sym_s){ sym_comment | s.as(:s) }
      rule(:sym_s_star){ sym_s.repeat }
      rule(:sym_badcomment){ badcomment.as(:badcomment) }
      rule(:sym_cdo){ str("<!--").as(:cdo) }
      rule(:sym_cdc){ str("-->").as(:cdc) }
      rule(:sym_includes){ str("~=").as(:includes) }
      rule(:sym_dashmatch){ str("|=").as(:dashmatch) }
      rule(:sym_string){ string.as(:string) }
      rule(:sym_badstring){ badstring.as(:badstring) }
      rule(:sym_ident){ ident.as(:ident) }

      rule(:sym_hash){ (str("#") >> name).as(:hash) }

      rule(:sym_import_sym){
        (str("@") >> cimatch_word("import")).as(:import_sym)
      }
      rule(:sym_page_sym){
        (str("@") >> cimatch_word("page")).as(:page_sym)
      }
      rule(:sym_media_sym){
        (str("@") >> cimatch_word("media")).as(:media_sym)
      }

      rule(:sym_charset_sym){
        str("@charset ").as(:charset_sym)
      }

      rule(:sym_important_sym){
        # NB deviation: s is a w in the spec
        (str("!") >> 
         (comment | s).repeat >> 
         cimatch_word("important")
         ).as(:important_sym)
      }
      

      rule(:sym_ems){
        (num.as(:num) >> cimatch_word("em").as(:unit)).as(:ems)
      }
      rule(:sym_exs){
        (num.as(:num) >> cimatch_word("ex").as(:unit)).as(:exs)
      }
      rule(:sym_length){
        units = %w{px cm mm in pt pc}
        unit_matcher = units.map{|u| cimatch_word(u)}.reduce(:|)

        (num.as(:num) >> unit_matcher.as(:unit)).as(:length)
      }
      rule(:sym_angle){
        units = %w{deg rad grad}
        unit_matcher = units.map{|u| cimatch_word(u)}.reduce(:|)

        (num.as(:num) >> unit_matcher.as(:unit)).as(:angle)
      }
      rule(:sym_time){
        units = %w{ms s}
        unit_matcher = units.map{|u| cimatch_word(u)}.reduce(:|)

        (num.as(:num) >> unit_matcher.as(:unit)).as(:time)
      }
      rule(:sym_freq){
        units = %w{hz khz}
        unit_matcher = units.map{|u| cimatch_word(u)}.reduce(:|)

        (num.as(:num) >> unit_matcher.as(:unit)).as(:freq)
      }
      rule(:sym_dimension){
        (num.as(:num) >> ident.as(:unit)).as(:dimension)
      }
      rule(:sym_percentage){
        (num.as(:num) >> str("%").as(:unit)).as(:percentage)
      }
      rule(:sym_number){ (num.as(:num)).as(:number) }
      rule(:sym_uri){
        (cimatch_word("url") >> str("(") >> 
         (string.as(:string) | url.as(:url)) >> 
         str(")")).as(:uri)
      }
      rule(:sym_js){ js_balancing }

      rule(:sym_baduri){ baduri.as(:baduri) }

      rule(:sym_function){ (ident.as(:name) >> str("(")).as(:function) }
      rule(:sym_expression){ cimatch_word("expression") >> str("(") }

      

      rule(:prod_hexcolor){ sym_hash >> sym_s_star }

      rule(:prod_operator){ match["/,"] >> sym_s_star }
      rule(:prod_unary_operator){ match["-+"] }
      rule(:prod_combinator){ match["+>"] >> sym_s_star }

      rule(:prod_function){
        sym_function >> sym_s_star >> prod_function_arglist >> str(")") >> sym_s_star
      }

      rule(:prod_expression){
        sym_expression >> sym_s_star >> sym_js.as(:js) >> str(")") >> sym_s_star
      }
      
      rule(:prod_maybe_named_arg){
        ((sym_ident >> str("=")).maybe >> prod_term)
      }

      rule(:prod_function_arglist){
        if @strict
          prod_expr
        else
          # This works around IE, which allows things like:
          # filter: alpha(opacity=90)
          prod_maybe_named_arg >> 
            ( prod_operator.maybe >> 
              prod_maybe_named_arg ).repeat
        end
      }

      rule(:prod_term){
        # expression() is a deprecated IE extension which allows arbitrary
        # JS expressions (!) to be used for property values. This was a STUPID
        # IDEA, but it's still used to give IE6 approximately modern functionality.
        ( @strict ? prod_function : (prod_expression | prod_function) ) |
        ( prod_unary_operator.maybe >> 
          ( sym_percentage | sym_length | sym_ems | sym_exs | sym_angle | 
            sym_time | sym_freq | sym_number ) >>
          sym_s_star ) |
        ( ( sym_string | sym_uri | sym_ident ) >> sym_s_star ) |
        prod_hexcolor
      }


      rule(:prod_expr){
        prod_term >> ( prod_operator.maybe >> prod_term ).repeat
      }

      rule(:prod_prio){ sym_important_sym >> sym_s_star }
      rule(:prod_property){ sym_ident >> sym_s_star  }
      rule(:prod_declaration){ 
        base = ( prod_property.as(:property) >> str(":") >> 
                 sym_s_star >> prod_expr.as(:value) >> prod_prio.maybe )
        # Only old IE versions need to pay attention to this. Or rather,
        # this is used to flag declarations as only applying to old IE versions,
        # because they don't correctly ignore the declaration.
        @strict ? base : ( str("*").maybe.as(:star) >> base )
      }

      rule(:prod_pseudo){
        str(":") >> ( ( sym_function >> sym_s_star >> 
                        ( sym_ident >> sym_s_star ).maybe >> str(")") ) | 
                      sym_ident)
      }

      rule(:prod_attrib){
        str("[") >> sym_s_star >> sym_ident.as(:key) >> sym_s_star >> 
        (
         ( sym_includes | sym_dashmatch | str("=") ) >> sym_s_star >>
         ( sym_string | sym_ident ).as(:value) >> sym_s_star
         ).maybe >>
        str("]")
      }
      
      rule(:prod_element_name){ sym_ident | str("*") }
      rule(:prod_class){ str(".") >> sym_ident }

      rule(:prod_simple_selector){
        ( prod_element_name >>
          ( sym_hash | prod_class | prod_attrib | prod_pseudo ).repeat ) |
        ( sym_hash | prod_class | prod_attrib | prod_pseudo ).repeat(1)
      }

      rule(:prod_selector){
        prod_simple_selector.as(:parent) >>
        ( ( prod_combinator >> prod_selector.as(:child) ) |
          ( sym_s.repeat(1) >> ( prod_combinator.maybe >> prod_selector.as(:child) ).maybe )
          ).maybe
      }

      rule(:prod_ruleset){
        prod_selector >> 
        ( str(",") >> sym_s_star >> prod_selector ).repeat >> 
        str("{") >> sym_s_star >>
        prod_declaration.maybe >>
        ( str(";") >> sym_s_star >> prod_declaration.maybe
         ).repeat >>
        str("}") >> sym_s_star
      }

      rule(:prod_pseudo_page){ str(":") >> sym_ident >> sym_s_star }
      rule(:prod_page){ sym_page_sym >> sym_s_star >>
        prod_pseudo_page.maybe >> str("{") >> sym_s_star >>
        prod_declaration.maybe >>
        ( str(";") >> sym_s_star >> prod_declaration.maybe
          ).repeat >>
        str("}") >> sym_s_star
      }

      rule(:prod_medium){ sym_ident >> sym_s_star }
      rule(:prod_media_list){
        # NB str(",") is for the missing COMMA symbol from the grammar
        prod_medium >> (str(",") >> sym_s_star >> prod_medium).repeat
      }
      rule(:prod_media){
        sym_media_sym >> sym_s_star >>  prod_media_list >> str("{") >> sym_s_star >>
        prod_ruleset.repeat >>
        str("}") >> sym_s_star
      }

      rule(:prod_import){
        sym_import_sym >> sym_s_star >> (sym_string | sym_uri) >> sym_s_star >>
        prod_media_list.maybe >>
        str(";") >> sym_s_star
      }

      rule(:prod_stylesheet){
        ( sym_charset_sym >> sym_string >> str(";") ).maybe >>
        ( sym_s | sym_cdo | sym_cdc ).repeat >>
        ( prod_import >>
          ( ( sym_cdo >> sym_s_star ) | (sym_cdc >> sym_s_star ) ).repeat ).repeat >>
        ( ( prod_ruleset | prod_media | prod_page ) >>
          ( ( sym_cdo >> sym_s_star ) | (sym_cdc >> sym_s_star ) ).repeat ).repeat
      }


      root(:prod_stylesheet)
    end # class CssLexer


  end # module Parser
end # module Excession
