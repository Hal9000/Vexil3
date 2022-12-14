<p>

<p>

(This README is adapted from a chapter of a book in progress)
<p>

<h3>Vexil and its Heritage</h3>
<p>

This is a simple "capture the flag" type of game. I call it Vexil (a name 
derived from the Latin <i>vexillum</i> for "flag").
<p>

Vexil is <i>not</i> a board game, although glancing at it might make you think so.
It actually derives from <b>([discuss</b> Core Wars and Darwin]).
<p>

In a board game like chess or checkers, there are two opponents, each with 
absolute knowledge of the entire board. But in Vexil, the opponents are more
like <i>teams</i> (labeled "red" and "blue"). Each player on a team is intended to 
act autonomously, with no global knowledge of the grid and no single point of
control.
<p>

So a good analogy is the "battling bots" type of game which we've seen many times
in the past. I'm sure you can see the direction this is going. Each player or 
piece will (ultimately) be controlled by a single process; these processes will
collaborate to defeat those on the other team. As such, it will finally be a 
battle of algorithms, where coders write their best logic for the bots and then
turn them loose on the grid. The "referee" process will manage communication, 
enforce the rules, prevent (easy) cheating, and declare a winner.
<p>

So on to the details. The Vexil grid is 21 by 21 for a total of 441 cells.
The Red team originates in the lower left portion, diagonally across from the
Blue team on the upper right.
<p>

Each team views the grid in its own coordinate system. The <i>x</i> and <i>y</i> values 
can vary from 1 to 21. For example, the cell that the Red team calls <tt>(3,5)</tt>
will be viewed as <tt>(19,17)</tt> from the Blue side.
<p>

Each team has a "flag" that is randomly placed by the referee within four cells
of the corner (i.e., somewhere in that 4-by-4 area). We'll call this zone 1.
Besides the flag, nothing starts out in this area,
<p>

There are three kinds of pieces or players. Each kind is characterized by its
abilities in several areas of behavior:
<p>

<ul>
<li>It can <i>see</i> a square sub-grid centered on itself and "know" what is in each of</li>
  the nearby occupied cells (friend or for or flag);
<li>It can <i>move</i> a certain number of cells per turn, any combination of horizontal</li>
  and vertical moves;
<li>It can <i>defend</i> itself by withstanding an attack up to a certain number of points</li>
  of damage;
<li>It can <i>attack</i> and inflict damage points on an opposing piece;</li>
<li>It can attack within a limited <i>range</i> (true distance between cells),</li>
</ul>
The following rules apply. Some are dictated by common sense, while others are
more or less arbitrary.
<p>

<ul>
<li>No cell can contain more than one piece at a time; possible collisions will be</li>
  resolved randomly.
<li>Every piece "knows" where its team's flag is.</li>
<li>No piece knows the enemy flag's location until it is in visual range.</li>
<li>A piece cannot "see" through other pieces regardless of range.</li>
<li>A piece can always see farther than it can move.</li>
<li>A piece always has an attack range less than its range of motion.</li>
<li>Pieces may communicate with their own team members (by "radio") regardless of </li>
  distance.
<li>Mutual attacks will be resolved randomly.</li>
<li>When a piece receives damage, it never recuperates; when its constitution (or</li>
  "hit points") reaches zero, it dies and is removed from the grid.
<li>Pieces never run out of "ammunition" (ability to attack).</li>
<li>Pieces may not attack their own team.</li>
<li>When a piece moves onto the cell containing the enemy's flag, the game is over.</li>
<li>A piece may of course not capture its own flag.</li>
</ul>
So as I said, there are three kinds of pieces. The <i>defender</i> cannot see or move
very far, but it can attack and it is difficult to kill. The <i>scout</i> can see far
and move quickly, but cannot attack (or withstand attacks) very well. The
<i>fighter</i> is faster than the defender but slower than the scout; it is tougher
than the scout, but not so tough as the defender; and it is the best attacker
of all. This information is summarized in this table:
<p>

<p>

<br><center><table width=90% cellpadding=5>
<tr>
  <td width=17% valign=top piece>        </td>
  <td width=17% valign=top piece>Can move</td>
  <td width=17% valign=top piece>Can see</td>
  <td width=17% valign=top piece>Defending</td>
  <td width=17% valign=top piece>Attacking</td>
  <td width=17% valign=top piece>Range</td>
</tr>
<tr>
  <td width=17% valign=top piece>Defender</td>
  <td width=17% valign=top piece>2</td>
  <td width=17% valign=top piece>3</td>
  <td width=17% valign=top piece>6</td>
  <td width=17% valign=top piece>4</td>
  <td width=17% valign=top piece>2</td>
</tr>
<tr>
  <td width=17% valign=top piece>Fighter </td>
  <td width=17% valign=top piece>4</td>
  <td width=17% valign=top piece>6</td>
  <td width=17% valign=top piece>6</td>
  <td width=17% valign=top piece>6</td>
  <td width=17% valign=top piece>4</td>
</tr>
<tr>
  <td width=17% valign=top piece>Scout   </td>
  <td width=17% valign=top piece>5</td>
  <td width=17% valign=top piece>8</td>
  <td width=17% valign=top piece>3</td>
  <td width=17% valign=top piece>2</td>
  <td width=17% valign=top piece>1</td>
</tr>
</table></center><br><br>
For those of us who are visually oriented, here is a diagram of the grid:
<p>

<p>

Zone 2 is an L-shaped area consisting of the 5-by-5 area nearest the corner,
<i>minus</i> the cells in zone 1. Here the referee randomly places three defenders.
<p>

Zones 3 and 4 are also L-shaped areas. The referee randomly populates zone 3
with six fighters and zone 4 with six scouts.
<p>

<p>

<h3>A First Approximation in Ruby</h3>
<p>

For a little more digestibility, this game is split into multiple files. Let's 
look first at a "roadmap" of these files and the classes and methods they define.
<p>

<pre>
  # File: examples/vexil0/grid.rb          
 
    class Grid                          
      def initialize                    
      def [](team, x, y)                
      def []=(team, x, y, obj)          
      def coordinates(team, x, y)       
  
  # File: examples/vexil0/ misc.rb                             
 
    class String                        
      def red                           
      def blue                          
 
  # File: examples/vexil0/referee.rb                         
 
    class Referee                       
      def initialize                    
      def show_cell(xx, yy)             
      def record(line)                  
      def display                       
      def [](team, x, y)                
      def setup                         
      def turn                          
      def pause                         
      def move(team, x0, y0, x1, y1)    
      def attack(qty, team, x, y)       
      def place(team, kind, x, y)       
      def over!                         
      def over?                         
 
  # File: examples/vexil0/pieces.rb                          
 
    class Bot                           
      def initialize(team, data, x, y)  
      def to_s                          
      def who                           
      def move(dx, dy)                  
      def move!(dx, dy)                 
      def where                         
      def enemy?(piece)                 
      def within(n)                     
      def can_see                       
      def can_attack                    
      def turn                          
      def attack(qty, team, x, y)       
 
    class Defender < Bot                
      def initialize(team, x, y)        
      def turn                          
 
    class Fighter < Bot                 
      def initialize(team, x, y)        
      def turn                          
 
    class Scout < Bot                   
      def initialize(team, x, y)        
      def turn                          
 
    class Flag < Bot                    
      def initialize(team, x, y)        
</pre>
<p>

The <tt>Grid</tt> class handles the logic of the "board" or "field" on which the pieces 
move. Coordinates are in <i>x-y</i> form and are relative to each team's corner. The
"absolute" coordinates are the red one (origin lower left). The coordinates are
1-based (ranging from 1 to 21).
<p>

The <tt>Referee</tt> class handles all the details of the game itself in an impartial 
way. For example, when a piece attacks another, the <tt>attack</tt> method in <tt>Referee</tt>
manages it, recording damage and removing dead pieces from the grid.
<p>

The <tt>display</tt> method shows the grid and ongoing history of the game on the
terminal; it currently works in a very "dumb" way by clearing the screen and
redrawing the contents. The pieces are colored via ANSI terninal codes; refer to 
the reopened <tt>String</tt> class with methods <tt>red</tt> and <tt>blue</tt> added.
<p>

To be continued...
<p>

