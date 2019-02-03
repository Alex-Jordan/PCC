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

F<parserGeoGebra.pl> - Use a GeoGebra applets as a Math Object

=head1 DESCRIPTION

This file implements a GeoGebra Math Object class. Its value is either empty
(if the applet is only used for display) or if the applet is tied to a hidden
answer blank, then the value is some other Math Object.

In HTML mode, the string method loads the applet in a div. If the applet is 
interacting with a hidden answer blank, the string method also makes the hidden 
answer blank.

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


To create a GeoGebra, use the GeoGebra constructor, GeoGebra(). There are three 
ways for an author to use a GeoGebra applet.

1. For display only, meaning the applet does not interact with a hidden answer
blank. For this, simply do

	$mygeogebra = GeoGebra();

with properties set as described below. 

2. As the student manipulates the applet, GeoGebra computes some string.
And you intend WeBWorK to Compute that string as a Math Object and the answer
checking is based on that. For example if the student is supposed to manipulate
two points so they form the line x+2y=3, then you might do

	Context("ImplicitPlane");
	$mygeogebra = GeoGebra("x+2y=3");

or

	Context("ImplicitPlane");
	$myplane = Compute("x+2y=3");
	$mygeogebra = GeoGebra($myplane");

It is wise to also communicate one possible way for the student to manipulate 
manipulable objects in the applet to acheive this. If the two points are named
A and B ub the applet, then you can do

	$mygeogebra = GeoGebra("x+2y=3", A => '(3,0)', B => '(1,1)'); 

or 

	$mygeogebra = GeoGebra("x+2y=3", A => Point(3,0), B => Point(1,1));

Here, A and B will be stored as keys in a "parameters" hash for the GeoGebra 
object, with their values being the Math Objects they point to.

Depending on the nature of the applet, other things might be the manipulable
parameters. For example,

        $mygeogebra = GeoGebra("x+2y=3", n => Vector(1,2), c => Real(3));

These parameters will be used in the default message to students displaying 
the correct answer in the results table. For example, the correct answer here 
would be:

"x+2y=3; For example set A to (3,0) and B to (1,1)."

3. As the student manipulates the applet, GeoGebra computes some score
between 0 and 1. When the student hits submit, this value is their score for
that attempt. You still define the Math Object as abovem except the first 
argument of the constructor should be a Score object, in particular, Score(1).

	$mygeogebra = GeoGebra(Score(1), A => '(3,0)', B => '(1,1)');

The presense of a Score object will change the behavior of the default correct
answer string to just say "For example set A to (3,0) and B to (1,1)."



A GeoGebra Math Object has some special properties listed below. Many of them are 
set to default values when the GeoGebra is initialized. They can be set with the
GeoGebra constructor like:

	$mygeogebra = GeoGebra()->with(
	  onload => '...',
	  width => 600,
	  height => 400,
	  ...
	);

Or they can be replaced with

	$mygeogebra->{property} = ...

Or appended to with

	$mygeogebra->{property} .= ...

C<{onload}> is a sequence of GeoGebra API commands to be run each time the 
applet loads. That includes each time the student submits an answer, which
causes the entire page to reload.

C<{update}> is a sequence of GeoGebra API commands to be run each time some
variable updates. Useful for when GeoGebra is interacting with a hidden
answer blank. Then when somthing is updated in the applet, this can repopulate
the hidden answer blank with a new string.

C<{material_id}> is a material id from the GeoGebra materials site. If this is
nonempty, then first the applet will load this material and then apply the
commands in {onload}. Only one of these three is used, in this preference order:
{base64} > {filename} > {material_id}. 

C<{filename}> is the path to a .ggb file. If this is nonempty, then first the 
applet will load this file and then apply the commands in {onload}. Only one of 
these three is used, in this preference order: 
{base64} > {filename} > {material_id}.  

C<{base64}> is a base64-encoded string containing a GeoGebra applet. These can
be exported from GeoGebra itself. If this is nonempty, then first the applet 
will load from this base64 string and then apply the commands in {onload}.
Only one of these three is used, in this preference order:
{base64} > {filename} > {material_id}. 

C<{width}, {height}> are pixel widths and heights for the applet in HTML.
Both have default values.

C<{center}> defaults to 1, meaning the applet will be centered.

C<{correct_ans}> is a string message to the student for how to obtain a 
correct answer. This makes sense when the GeoGebra is tied to a hidden answer
blank. This string is what will appear in the correct answers table when 
students are allowed to see correct answers. For example, you might set it to 
"Move the slider for c to 1.618". There is a sensible default for correct_ans. 

C<{correct_ans_latex_string}> will be set to the empty string by default,
so that it is not used to override correct_ans in the results table. Most of
the time, the correct_ans message will be a complete sentence, and if
correct_ans_latex_string is used, it will be in math mode in \text{} and 
it will not permit line breaking.

C<{label}> is a name for a hidden answer blank associated with the GeoGebra.
In most cases you would let this be its default.

C<{extra_parameters}> The js that activates the applet can be passed any
of the parameters listed at wiki.geogebra.org/en/Reference:GeoGebra_App_Parameters
Values for some of these are automatic using the MathObject parameters we
are discussing. But if you were to use, say

	$mygeogebra->{extra_parameters} = 'showAlgebraInput: true, showResetIcon: true';

then these would be applied at the end of the call to load the applet. Note
these could overrule other parameters defined earlier.



If you are using the GeoGebra to interact with a hidden answer blank, there
are two things to understand.

A. The {onupdate} commands should include a command to populate the hidden 
answer field with a string. See examples below.

B. The {onload} command should include a command that looks at the hidden 
answer blank and uses the test in there to set some values in the applet.
Otherwise when the student submits an answer and the applet reloads, everythin
resets to the original configuration instead of retaining their manipulations.
See exmaples below.



The default answer checker for a GeoGebra will simply be based on the primary
Math Object that was used in its construction. This was Compute("x+2y=3") and
Score(1) in two examples above. Actually the answer blank will be populated by 
GeoGebra with strings that include manipulable object settings like

	x+2y=3; A = (3,0); B = (1,1)

or

	1; A = (3,0); B = (1,1)

but the checker knows to only work with what comes before the first semicolon.

If you need to make a custom checker for a GeoGebra, you will need to understand
that this is the form that is populating the hidden answer blank. 





Examples here.


=cut


loadMacros("MathObjects.pl", "contextArbitraryString.pl");

HEADER_TEXT('<script src="https://cdn.geogebra.org/apps/deployggb.js"></script>
<script src="https://cdn.jsdelivr.net/npm/ww_ggb_applet/lib/ww_ggb_applet.js"></script>');


sub _parserGeoGebra_init {
  main::PG_restricted_eval('sub GeoGebra {GeoGebra->new(@_)}');
  main::PG_restricted_eval('sub Score {Score->new(@_)}');
}

package GeoGebra;
our @ISA = qw(Value);

my $context = Parser::Context->getCopy("ArbitraryString");

$context->{name} = "GeoGebra";

sub new {
    my $self = shift; my $class = ref($self) || $self;
    my $correct = shift;
    $correct = main::Real(1) unless defined($correct);
    $correct = Value::makeValue($correct) unless Value::isValue($correct);
    $correct = $correct->{correct} if Value::classMatch($correct, 'GeoGebra');
    #...
    # Probabilistic way to prevent duplicate id~s on the same page
    my $label = random_string(16);
    my $geogebra = bless {
      context => $context,
      correct => $correct,
      onupdate => '',
      onload => '',
      material_id => '',
      base64 => '',
      width => 400,
      height => 400,
      center => 1,
      correct_ans => '',
      correct_ans_latex_string => '',
      label => $label,
      extra_parameters => '',
      #...
    }, $class;
    #...
    $geogebra->{onload} = qq!applet.evalCommand('SetPerspective("G")'); \n applet.setAxisLabels(1,"x","y","z"); \n applet.setGridVisible(true);!
        if !($geogebra{material_id} || $geogebra{base64});
    return $geogebra;
}

sub random_string {
    my $length = shift;
    my $out = '';
    for my $i (1..$length) {
       $out .= chr(main::random(97,122));
    }
    return $out;
}

sub string {
    my $self = shift;
    my $tex = 'A GeoGebra applet goes here.';
    my $ptx = '<p>A GeoGebra applet goes here.</p>';
    my $html = "<div id='geogebra-" . $self->{label} . "' class='ww-ggb'";
    $html .= " style='margin:auto;'" if $self->{center};
    $html .= "></div>\n";
    $html .= "<script>\n";
    $html .= "var onUpdate = function(obj) {\n";
    $html .= $self->{onupdate};
    $html .= "}\n";
    $html .= "var onLoad = function(applet) {\n";
    $html .= $self->{onload};
    $html .= "}\n";
    $html .= "new WwGgbApplet('geogebra-" . $self->{label} . "', {width: ";
    $html .= $self->{width};
    $html .= ", height: ";
    $html .= $self->{height};
    if ($self->{base64}) {
        $html .= ", ggbBase64: '";
        $html .= $self->{base64};
        $html .= "'"; }
    elsif ($self->{filename}) {
        $html .= ", filename: '";
        $html .= $self->{filename};
        $html .= "'"; }
    elsif ($self->{material_id}){
        $html .= ", material_id: '";
        $html .= $self->{material_id};
        $html .= "'"; };
    $html .= ", appletOnLoad: onLoad, appletOnUpdate: onUpdate, enableShiftDragZoom: false, showResetIcon: true, showFullscreenButton: true";
    do {$html .= ", ";
        $html .= $self->{extra_parameters}} if ($self->{extraparameters});
    $html .= "});\n"; 
    $html .= "</script>\n";
    return main::MODES(TeX=>$tex, PTX=>$ptx, HTML=>$html);
}




package Score;
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


1;

