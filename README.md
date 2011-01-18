Excession
=========

A library for modifying CSS files.

Currently only supports global hue rotation.


Quick and Dirty
---------------

Look at Excession::CssRegexHueMod:


    str = <<-CSS
    body {
      background-color: #ff0000;
    }
    CSS
    
    Excession::CssRegexHueMod.new.rotate_hue(120, str)
      # => "body {
      #  background-color: #00ff00;
      #}

This will recolour declarations of the form:

  * #XXXXXX
  * #YYY
  * rgb(XXX, XXX, XXX)
  * rgb(XXX%, XXX%, XXX%)
  
It does not recolour named colours, because without doing a full
parse I can't tell with just a regular expression what is a colour
and what is part of a selector.


Proper
------

There is a CSS parser in Excession::Parser::CssParser. This interface
is incomplete because it is very slow (8 minutes to parse a 3500-line CSS
file). There's a big TODO over this.

Author
------

Alex Young <alex@blackkettle.org>
