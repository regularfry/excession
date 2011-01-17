# encoding: utf-8
require 'test/helper'
require 'excession/parser/css_parser'


module TestExcession
  module TestParser

    class TestCssParser  < Test::Unit::TestCase
      
      include Excession::Parser
      
      def setup
        @l = CssParser.new
      end
      
      def assert_parse(meth, str)
        result = nil
        assert_nothing_raised("#{str.inspect} was not matched!") do
          result = @l.__send__(meth).parse(str)
        end
        assert_equal( str, result )
      end

      # A looser version of the above
      def ok(meth, str)
        assert_nothing_raised("#{str.inspect} was not matched!") do
          assert( @l.__send__(meth).parse(str), 
                  "#{str.inspect} was not matched!")
        end
      end

      def assert_no_parse(meth,str)
        assert_raises(Parslet::ParseFailed){ @l.__send__(meth).parse(str) }
      end



      def test_h
        assert_parse(:h, "a")
        assert_no_parse(:h, "z")
      end


      def test_nonascii
        assert_parse(:nonascii, "\200".force_encoding("BINARY"))
        assert_no_parse(:nonascii,"a")
      end


      def test_unicode
        assert_parse(:unicode, "\\abcde0\n".force_encoding("BINARY"))
        assert_parse(:unicode, "\\abcde0".force_encoding("BINARY"))
        assert_parse(:unicode, "\\ABCDE0".force_encoding("BINARY"))

      end

      
      def test_escape
        assert_parse(:escape, "\\abcde0\n".force_encoding("BINARY"))
        assert_parse(:escape, "\\\\z")
        assert_no_parse(:escape,"\\\\1")
      end


      def test_nmstart
        assert_parse(:nmstart, "a")
        assert_parse(:nmstart, "A")
        assert_no_parse(:nmstart, "9")
        assert_no_parse(:nmstart, ".")
        assert_parse(:nmstart, "\200".force_encoding("BINARY"))
        assert_parse(:nmstart, "\\\\z")
      end


      def test_nmchar
        assert_parse(:nmchar, "a")
        assert_parse(:nmchar, "A")
        assert_parse(:nmchar, "9")
        assert_parse(:nmchar, "\200".force_encoding("BINARY"))
        assert_parse(:nmchar, "\\\\z")
        assert_no_parse(:nmchar,".")
      end


      def test_string1
        assert_parse(:string1, '"a"')
        assert_no_parse(:string1, '"a')
        assert_parse(:string1, '"aa"')
        assert_parse(:string1, '""')

        assert_parse(:string1, '"\\\n"'.force_encoding("BINARY"))
        assert_parse(:string1, '"a\\\\z"')
      end


      def test_string2
        assert_parse(:string2, %q{'a'})
        assert_no_parse(:string2, "'a")
        assert_parse(:string2, "'aa'")
        assert_parse(:string2, "''")

        assert_parse(:string2, %q{'\\\n'}.force_encoding('BINARY'))
        assert_parse(:string2, "'a\\\\z'")
      end


      def test_badstring1
        assert_parse(:badstring1, '"a')
        assert_parse(:badstring1, '"a\\')
        assert_no_parse(:badstring1, '"a"')
      end
      

      def test_badstring2
        assert_parse(:badstring2, "'a")
        assert_parse(:badstring2, "'a\\")
        assert_no_parse(:badstring2, "'a'")
      end
      

      def test_badcomment1
        assert_parse(:badcomment1, '/**')
        assert_parse(:badcomment1, '/***')
        assert_parse(:badcomment1, '/* *')
        assert_parse(:badcomment1, '/**a*')
        assert_parse(:badcomment1, '/**a/*')
      end

      
      def test_badcomment2
        assert_parse(:badcomment2, '/*')
        assert_parse(:badcomment2, '/*a')
        assert_parse(:badcomment2, '/*aa')
        assert_parse(:badcomment2, '/**a')
      end

      
      def test_js_balancing
        ["a", "()", "()()", "(())"].each do |js|
          assert_parse(:js_balancing, js)
        end
      end

      
      def test_s
        %W{\t \r \n \f}.each{|c|
          assert_parse(:s, c)
        }
        assert_parse(:s, " \t")
      end

      def test_w
        assert_parse(:w, "")
        assert_parse(:w, " ")
      end

      def test_baduri1
        assert_parse(:baduri1, "url(")
        assert_parse(:baduri1, "url( ")
        assert_parse(:baduri1, "url(!")
        assert_parse(:baduri1, "url(".force_encoding("BINARY") << 0x80)
        assert_parse(:baduri1, "url(\\\\z")
        assert_parse(:baduri1, "url(! ")
      end

      def test_string
        assert_parse(:string, '"foo"')
        assert_parse(:string, "'foo'")
      end

      def test_baduri2
        assert_parse(:baduri2, "url('foo'")
        assert_parse(:baduri2, "url( 'foo'")
        assert_parse(:baduri2, "url('foo' ")
      end


      def test_badstring
        assert_parse(:badstring, "'a")
        assert_parse(:badstring, '"a')
      end

      def test_baduri3
        assert_parse(:baduri3, "url('foo")
        assert_parse(:baduri3, 'url("foo')
        assert_parse(:baduri3, "url( 'foo")
      end

      def test_comment
        assert_parse(:comment, "/**/")
        assert_parse(:comment, "/*a*/")
        assert_parse(:comment, "/***/")
        assert_parse(:comment, "/***a**/")
      end

      def test_ident
        assert_parse(:ident, "a")
        assert_parse(:ident, "a9")
        assert_parse(:ident, "a99")
        assert_parse(:ident, "-a99")
        assert_parse(:ident, "aA")
      end

      def test_name
        assert_parse(:name, "9")
        assert_parse(:name, "aA")
        assert_no_parse(:name, "")
        assert_parse(:name, "99")
      end

      def test_num
        assert_parse(:num, "9")
        assert_no_parse(:num, "a")
        assert_parse(:num, "99")

        assert_parse(:num, ".9")
        assert_no_parse(:num, ".")
        assert_parse(:num, "3.9")
        assert_parse(:num, "3.95")
        assert_parse(:num, "23.95")
      end

      def test_badcomment
        assert_parse(:badcomment, "/*")
        assert_parse(:badcomment, "/**")
      end
      
      
      def test_baduri
        assert_parse(:baduri, "url(")
        assert_parse(:baduri, "url('foo'")
        assert_parse(:baduri, "url('foo")
      end

      def test_url
        assert_parse(:url, "")
        assert_parse(:url, "!")
        assert_parse(:url, '!#$%')
        assert_parse(:url, "\200".force_encoding("BINARY"))
      end
      

      def test_nl
        assert_parse(:nl, "\n")
        assert_no_parse(:nl, "a")
        assert_parse(:nl, "\r\n")
        assert_parse(:nl, "\r")
        assert_parse(:nl, "\f")
      end


      def assert_node(sym, str)
        assert_equal( {sym => str}, @l.__send__(:"sym_#{sym}").parse(str) )
      end


      def test_sym_s
        assert_node( :s, ' ' )
        ok :sym_s, "/**/"
      end

      def test_sym_comment
        assert_node( :comment, "/*foo*/" )
      end

      def test_sym_bad_comment
        assert_node( :badcomment, "/*" )
      end

      def test_sym_cdo
        assert_node( :cdo, "<!--" )
      end

      def test_sym_cdc
        assert_node( :cdc, "-->" )
      end

      def test_sym_includes
        assert_node( :includes, "~=" )
      end

      def test_sym_dashmatch
        assert_node( :dashmatch, "|=" )
      end

      def test_sym_string
        assert_node( :string, '"foo"' )
      end

      def test_sym_badstring
        assert_node( :badstring, '"foo' )
      end

      def test_sym_ident
        assert_node( :ident, "abc" )
      end

      def test_sym_hash
        assert_node( :hash, "#foo" )
      end

      def test_sym_import_sym
        assert_node( :import_sym, "@import" )
        assert_node( :import_sym, "@IMPoRT" )
        assert_node( :import_sym, "@impor\\54" )
      end
      
      def test_sym_page_sym
        assert_node( :page_sym, "@page" )
      end

      def test_sym_media_sym
        assert_node( :media_sym, "@media" )
      end

      def test_sym_charset_sym
        assert_node( :charset_sym, "@charset " )
        assert_no_parse( :sym_charset_sym, "@CHARSET " )
      end


      def test_sym_important_sym
        assert_node( :important_sym, "!important" )
        assert_node( :important_sym, "!ImPoRtaNt" )
        assert_node( :important_sym, "! important" )
        assert_node( :important_sym, "!/*foo*/important" )
        assert_node( :important_sym, "!/*foo*/ /*foo*/ important" )
      end

      def test_sym_ems
        assert_equal( {:ems => {:num => "3", :unit => "em"}},
                      @l.sym_ems.parse("3em") );
      end

      def test_sym_exs
        assert_equal( {:exs => {:num => "3", :unit => "ex"}},
                      @l.sym_exs.parse("3ex") );
      end

      def test_sym_length
        units = %w{px cm mm in pt pc}
        units.each do |unit|
          assert_equal( {:length => {:num => "3", :unit => unit}},
                        @l.sym_length.parse("3"+unit) );
        end
      end

      def test_sym_angle
        units = %w{deg rad grad}
        units.each do |unit|
          assert_equal( {:angle => {:num => "3", :unit => unit}},
                        @l.sym_angle.parse("3"+unit) );
        end
      end

      def test_sym_time
        units = %w{ms s}
        units.each do |unit|
          assert_equal( {:time => {:num => "3", :unit => unit}},
                        @l.sym_time.parse("3"+unit) );
        end
      end

      def test_sym_freq
        units = %w{hz khz}
        units.each do |unit|
          assert_equal( {:freq => {:num => "3", :unit => unit}},
                        @l.sym_freq.parse("3"+unit) );
        end
      end

      def test_sym_dimension
        assert_equal( {:dimension => {:num => "3", :unit => "foo"}},
                      @l.sym_dimension.parse("3foo") );
      end

      def test_sym_percentage
        assert_equal( {:percentage => {:num => "3", :unit => "%"}},
                      @l.sym_percentage.parse("3%") )
      end

      def test_sym_number
        assert_equal( {:number => {:num =>  "3"}},
                      @l.sym_number.parse("3") )
      end

      def test_sym_uri
        assert_equal( {:uri => {:string => "'foo'"}},
                      @l.sym_uri.parse("url('foo')") )
        assert_equal( {:uri => {:url => "foo"}},
                      @l.sym_uri.parse("url(foo)") )

      end


      def test_sym_baduri
        assert_node( :baduri, "url(foo" )
      end

      def test_function
        assert_equal( {:function => {:name => "bar"}},
                      @l.sym_function.parse("bar(") )
      end
      

      def test_prod_hexcolor
        ok(:prod_hexcolor, "#aabbcc")
        ok(:prod_hexcolor, "#aabbcc ")
      end

      def test_prod_operator
        ["/", ",", "/ ", ", "].each do |op|
          ok :prod_operator, op
        end
      end

      def test_prod_unary_operator
        ["-", "+"].each do |op|
          ok :prod_unary_operator, op
        end
      end

      
      def test_prod_term
        ["1", "1 ", "-1", "-1 ",
         "42%", "42% ",
         "12cm", "23em", "42ex",
         "90deg", "12ms", "12Hz",
         '"string"',
         'foo',
         'url(foo)',
         "expression(this.clientWidth > 140 ? '140px':true)",
         "#aabbcc",
         "abc(1)"
        ].each do |term|
          ok :prod_term, term
        end
      end
      

      def test_prod_expr
        ["1", "1 / 1", "1/1/1" ].each do |term|
          ok :prod_expr, term
        end
      end

      def test_prod_function
        ["abc(1%)", "abc('a', 100, 3px)",
         "alpha(opacity=90)"#, # Used by IE, not 2.1 conformant
         #"expression(this.clientWidth > 140 ? '140px':true)"
        ].each do |func|
          ok :prod_function, func
        end
      end

      def test_prod_arglist
        ["90"].each do |arglist|
          ok :prod_function_arglist, arglist
        end
      end

      def test_prod_prio
        ok :prod_prio, "!important  "
      end

      def test_prod_property
        ok :prod_property, "foo "
      end

      def test_prod_declaration
        ['foo: this "that" 12%',
         '*foo: this "that" 12%'
        ].each do |declaration|
          ok :prod_declaration, declaration
        end
      end


      def test_prod_pseudo
        [':foo', ":lang(foo)"].each do |pseudo|
          ok :prod_pseudo, pseudo
        end
      end

      def test_prod_attrib
        ["[foo]", "[foo=bar]", '[foo="bar"]'].each do |attrib|
          ok :prod_attrib, attrib
        end
      end

      def test_prod_element_name
        ["foo", "*"].each{|name| ok :prod_element_name, name}
      end

      def test_prod_class
        ok :prod_class, ".foo"
      end

      def test_prod_simple_selector
        ["foo", 
         "foo#bar", "foo.bar", "foo[bar]", "foo:bar", 
         "foo[bar]:qux",
         "#bar", ".bar", "[bar]", ":bar"
        ].each do |ss|
          ok :prod_simple_selector, ss
        end
      end

      
      def test_prod_combinator
        ["+", "+ ", ">", "> "].each do |comb|
          ok :prod_combinator, comb
        end
      end

      def test_prod_selector
        ["foo", "foo>bar", "foo bar", "foo +bar",
         "div ol > li p"
        ].each do |sel|
          ok :prod_selector, sel
        end
      end

      def test_prod_ruleset
        ["foo{}",
         "foo {\n}",
         "foo, bar {}",
         "foo\n{\nbar: qux\n}",
         "foo{\nbar: qux}",
         "foo{\nbar: qux;foo: 1em}",
         "foo{
bar: qux;
foo: 1em
}"
        ].each do |ruleset|
          ok :prod_ruleset, ruleset
        end
      end

      def test_prod_pseudo_page
        ok :prod_pseudo_page, ":abc "
      end

      
      def test_prod_page
        ["@page{}", "@page :foo{}",
         "@page{foo:bar} ",
         "@page{\nfoo: bar;\nqux: 23 skidoo;}"
        ].each do |page|
          ok :prod_page, page
        end
      end


      def test_prod_medium
        ok :prod_medium, "foo "
      end

      def test_prod_media_list
        ["foo", "foo ", "foo, bar", "foo , bar ,qux"].each do |media|
          ok :prod_media_list, media
        end
      end

      def test_prod_media
        ["@media foo {}",
         "@media foo, bar {
foo > bar {
  qux: 29Hz;
  spang: foo \"bar\" qux
}
}
",
         "@media foo, bar {
foo > bar {
  qux: 29Hz;
  spang: foo \"bar\" qux
}

#thing {
  speng: wibble
}
}
"        ].each do |media|
          ok :prod_media, media
        end
        
      end
      
      def test_prod_import
        ["@import \"foo\"; ",
         "@import url(foo);",
         "@import 'foo' this, that;"
        ].each do |import|
          ok :prod_import, import
        end
      end


      def test_prod_stylesheet
        ss = []
        ss << "@charset 'UTF-8';"
        ss << "<!-- -->"
        ss << "@import url(foo);"
        ss << "@import url(foo); <!-- -->"

        ss << <<-RULE
foo {
  bar: qux;
}
RULE

        ss << <<-MEDIA
@media foo, bar {
  foo > bar {
    qux: 29Hz;
    spang: foo \"bar\" qux
  }

  #thing {
    speng: wibble
  }
}
MEDIA

        ss << <<-PAGE
@page :first {
  margin-left: 4cm;
  margin-right: 3cm;
}

PAGE

        ss << <<-RULE
foo {
  bar: qux;
}
foo > bar {
  thing: thang;
}
RULE

        # Check that we don't barf on arbitrary collections of
        # comments
        ss << <<-COMMENTED
/***************************
***************************/

/**
**/

/* foo */
/* MAIN FOO */
.subDmenu {
	position:absolute;
	display:none;
	visibility:hidden;
}
COMMENTED


        ss << <<-CHINDENT
.menu 
{
	position:absolute;
	display:none;
	visibility:hidden;
	background-color:#f6f6f6;
	z-index: 2;
	border: #999999 solid 1px;
	filter:alpha(opacity=90);
	-moz-opacity:0.9;
	opacity: 0.9;
/*	width:150px;*/
}
CHINDENT
        ss.each do |stylesheet|
          ok :prod_stylesheet, stylesheet
        end
      end


    end # class TestCssParser


  end # module TestParser
end # module TestExcession
