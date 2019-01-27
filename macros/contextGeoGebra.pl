################################################################################
# WeBWorK Online Homework Delivery System
# Copyright &copy; 2000-2018 The WeBWorK Project, http://openwebwork.sf.net/
# $CVSHeader$
# 
# This program is free software; you can redistribute it and/or modify it under
# the terms of either: (a) the GNU General Public License as published by the
# Free Software Foundation; either version 2, or (at your option) any later
# version, or (b) the "Artistic License" which comes with this package.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See either the GNU General Public License or the
# Artistic License for more details.
################################################################################

=head1 NAME

F<contextGeoGebra.pl> - Context for using GeoGebra applets as a MathObject

=head1 DESCRIPTION

This file implements a context in which the problem author can define a GeoGebra
MathObject. 

In HTML mode, the string method of the GeoGebra is the HTML that loads the applet
in a div. If the applet is interacting with a hidden answer blank, the string
method also makes the hidden answer blank.

In TeX mode, the string method is a message stating that a GeoGebra applet is here. 
A future version may be able to generate a png of the GeoGebra's initial state for 
TeX mode output.

So for example, 

	BEGIN_PGML
	[$mygeogebra]*
	END_PGML

or

	BEGIN_TEXT
	$mygeogebra
	END_TEXT

should insert the applet (or message, or image file).

A GeoGebra MathObject has some special properties. Many of them are set to
default values when the GeoGebra is initialized. They can be replaced with

	$mygeogebra->{property} = ...

or appended to with

	$mygeogebra->{property} .= ...

C<{onload}> is a sequence of GeoGebra API commands to be run each time the 
applet loads. That includes each time the student submits an answer, which
causes the entire page to reload.

C<{update}> is a sequence of GeoGebra API commands to be run each time some
variable updates. Useful for when GeoGebra is interacting with a hidden
answer blank. Then when somthing is updated in the applet, this can populate
the hidden answer blank with a new string.

C<{material}> is a material id from the GeoGebra materials site. If this is
nonempty, then first the applet will load this material and then apply the
commands in {onload}. If both {material} and {base64} are nonempty, {material} 
is ignored.

C<{base64}> is base64 for a GeoGebra applet. If this is nonempty, then first
the applet will load from this base64 and then apply the commands in {onload}.
If both {material} and {base64} are nonempty, {material} is ignored.

C<{width}, {height}> are pixel widths and heights for the applet in HTML.
Both have default values.

C<{center}> defaults to 1, meaning the applet will be centered.

C<{correct_ans}> is a string message to the student for how to obtain a 
correct answer. This makes sense when the GeoGebra is tied to a hidden answer
blank. This string is what will appear in the correct answers table when 
students are allowed to see correct answers. For example, you might set it to 
"Move the slider for c to 1.618". By default, this message is ... ?

C<{label}> is a name for a hidden answer blank associated with the GeoGebra.
In most cases you would let this be its default.

C<{extra_parameters}> The js that activates the applet can be passed any
of the parameters listed at wiki.geogebra.org/en/Reference:GeoGebra_App_Parameters
Values for some of these are automatic using the MathObject parameters we
are discussing. But if you were to use, say

	$mygeogebra->{extra_parameters} = 'showAlgebraInput: true, showResetIcon: true';

then these would be applied at the end of the call to load the applet. Note
these could overrule other parameters defined earlier.

C<{checker}> A subroutine to do the checking on what has been inserted in the
hidden answer blank. Expect answer blanks to be populated with a semicolon-separated 
list like 

	x+2y=3; A = (3,0); B = (1,1)

Typically, the answer checker should just look at the first item in the list,
compute it as a MathObject, and test it in context. If you are having GeoGebra 
calcluate a score instead of WeBWorK, then the answer blank will be populated
with something like

	1; A = (3,0); B = (1,1)

and you created the GeoGebra MathObject using a Score object as explained below.
The default checker assumes this is the situation you are in, assesses the first
item in the list as a Score, and awards that score to the student.



To create a GeoGebra, load the GeoGebra context, and then use the GeoGebra
initializer. There are three ways for an author to use a GeoGebra applet.

1. For display only, meaning the applet does not interact with a hidden answer
blank. For this, simply do

	$mygeogebra = GeoGebra();

and then define its properties. 

2. As the student manipulates the applet, GeoGebra computes some string.
And you intend WeBWorK to Compute that string as a MathObject and the answer
checking is based on that. For example if the student is supposed to manipulate
two points so they form the line x+2y=3, then you might use

	$mygeogebra = GeoGebra("x+2y=3");

It is wise to also communicate one possible way to manipulate manipulable 
objects in the applet to acheive this. If the two points were A and B, then
you can do

	$mygeogebra = GeoGebra("x+2y=3", A => '(3,0)', B => '(1,1)'); 

All of this will be used as the default for displaying the correct answer in
the results table. For example, the correct answer here would display as
"x+2y=3; For example set A to (3,0) and B to (1,1)."
Note that there will be no automated checking based on what you input here, 
and you will need to write a custom answer checker as described farther below.

3. As the student manipulates the applet, GeoGebra computes some score
between 0 and 1. When the student hits submit, this value is their score for
that attempt. You still define the MathObject as above. If nothing makes
sense to take the place of "x+2y=3", use Score(1) as in

	$mygeogebra = GeoGebra(Score(1), A => '(3,0)', B => '(1,1)');

The presense of a Score object will change the behavior of the default correct
answer string to just say "For example set A to (3,0) and B to (1,1)."


If you are using the GeoGebra to interact with a hidden answer blank, there
are three things to understand.

A. The {onupdate} commands should include a command to populate the hidden 
answer field with a string. See example below.

B. The {onload} command should include a command that looks at the hidden 
answer blank and uses the test in there to set some values in the applet.
Otherwise when the student submits an answer and the applet reloads, everythin
resets to the original configuration instead of retaining their manipulations.

C. If you have GeoGebra assess a score and used Score(1) as described above,
the default checker will know what to do. Otherwise, you need a checker where
you can trust that the applet has inserted a semicolon-separated string like

	x+2y=3; A = (3,0); B = (1,1)

into the hidden answer blank, and you write the checker to process that. 
Typically, the answer checker should just look at the first item in the list,
compute it as a MathObject, and test it in context.


Examples here.


=cut

loadMacros("contextArbitraryString.pl");

HEADER_TEXT('<script type="text/javascript" src="https://cdn.geogebra.org/apps/deployggb.js"></script>
<script type="text/javascript" src="https://cdn.jsdelivr.net/npm/ww_ggb_applet/lib/ww_ggb_applet.js"></script>');

sub _contextGeoGebra_init {parser::GeoGebra::Init()}

package parser::GeoGebra;
our @ISA = ('Value::String');

#
#  Initialization sets up a Score() and GeoGebra constructor and
#  creates the GeoGebra context.
#
sub Init {
  my $context = $main::context{GeoGebra} = Parser::Context->getCopy("Numeric");
  $context->{name} = "GeoGebra";
  $context->parens->clear();
  $context->variables->clear();
  $context->constants->clear();
  $context->operators->clear();
  $context->functions->clear();
  $context->strings->clear();
  $context->variables->{patterns} = {};
  $context->strings->{patterns}{"(.|\n)*"} = [0,'str'];
  $context->{value}{"GeoGebra()"} = "context::GeoGebra";
  $context->{value}{"GeoGebra"} = "context::GeoGebra::Value::String";
  $context->{parser}{GeoGebra} = "context::GeoGebra::Parser::String";

  $context->{value}{Score} = "Score::Score";

  $context->update;
  main::PG_restricted_eval('sub Score {Value->Package("Score")->new(@_)}');
  main::PG_restricted_eval('sub GeoGebra {context::GeoGebra::new(@_)}');
}

######################################################################
######################################################################
#
#  This is the MathObject class for Score objects.
#  It is basically a Real(), but the checker returns whatever was
#  submitted by the 'student'.
#
package Score::Score;
our @ISA = ('Value::Real');

#
#  We need to override the new() method
#  so that the Score object will be counted as
#  a Value object.  
#
sub new {
  my $self = shift; my $class = ref($self) || $self;
  my $context = (Value::isContext($_[0]) ? shift : $self->context);
  my $x = shift;
  Value::Error("A score must be a real number between 0 and 1")
      if !($x >= 0 && $x <= 1) or !Value::isRealNumber($x);
  $self = bless $self->SUPER::new($context,$x,@_), $class;
  $self->{isReal} = $self->{isValue} = $self->{isScore} = 1;
  return $self;
}

#
#  Override the class name to get better error messages
#
sub cmp_class {"a Score Value"}


sub cmp_defaults {(
  (shift)->SUPER::cmp_defaults,
  checker => sub {
    my ($correct, $student, $ansHash) = @_;
    Value::Error('A score must be a real number between 0 and 1')
      if !($student >= 0 && $student <= 1);
    return $student;
  },
)}


#
#  Handle creating String() constants
#
package context::GeoGebra;
sub new {shift; main::Compute(@_)}

#
#  Replacement for Parser::String that uses the original string verbatim
#  (but replaces \r and \r\n by \n to handle different browser multiline input)
#
package context::GeoGebra::Parser::String;
our @ISA = ('Parser::String');

sub new {
  my $self = shift;
  my ($equation,$value,$ref) = @_;
  $value = $equation->{string};
  $value =~ s/\r\n?/\n/g;
  $self->SUPER::new($equation,$value,$ref);
}

sub string {
  my $self = shift; my $equation = shift; my $prec = shift;
  $out = <<"END";
<div id='applet2' class='ww-ggb' style='margin:auto;'></div>
<script>
  var onUpdate = function(obj) {
  }

  var onLoad = function(applet) {
    applet.setCoordSystem(-6.5, 6.5, -6.5, 6.5);
    
    applet.evalCommand("L = Line[A, B]");
    applet.evalCommand("Solution: y = $m x");
    applet.setVisible("Solution", false);
  }
  
  new WwGgbApplet('applet2', {width: 400, height: 400, appletOnLoad: onLoad, appletOnUpdate: onUpdate, hideAnswers: true}); 
</script>
END

  return MODES(TeX => '', PTX => '', HTML => $out.'taco');
}

#
#  Replacement for Value::String that creates preview strings
#  that work for multiline input
#
package context::GeoGebra::Value::String;
our @ISA = ("Value::String");

#
#  Mark a multi-line string to be displayed verbatim in TeX
#
sub quoteTeX {
  my $self = shift; my $s = shift;
  return $self->verb($s) unless $s =~ m/\n/;
  my @tex = split(/\n/,$s);
  foreach (@tex) {$_ = $self->verb($_) if $_ =~ m/\S/}
  "\\begin{array}{l}".join("\\\\ ",@tex)."\\end{array}";
}

#
#  Quote HTML special characters
#
sub quoteHTML {
  my $self = shift;
  my $s = $self->SUPER::quoteHTML(shift);
  $s = "<pre style=\"text-align:left; padding-left:.2em\">$s</pre>"
    unless ($main::displayMode eq "TeX" or $main::displayMode eq "PTX");
  return $s;
}

#
#  Adjust preview and strings so they display
#  multiline answers properly.
#
sub cmp_preprocess {
  my $self = shift; my $ans = shift;
  if ($self->getFlag("noLaTeXresults")) {
    $ans->{preview_latex_string} = $self->getFlag("noLaTeXstring");
    $ans->{correct_ans_latex_string} = "";
  } else {
    $ans->{preview_latex_string} = $ans->{student_value}->TeX
      if defined $ans->{student_value};
  }
  $ans->{student_ans} = $self->quoteHTML($ans->{student_value}->string)
    if defined $ans->{student_value};
}
1;
