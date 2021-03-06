// sample set visualization (set'o'gram)
// inspired by 'Interactive Visual Analysis of Set-Typed Data'

// data file
int data = 0;
String[] fileNames = {"Titanic", "Titanic Alternative", "Penn World Table", "Labor Supply", "Genes"};
String extension = ".csv";
String fileLocation = "data/";
String oddData = "first-class";

// raw data variables
String[] sets;
int setCount;
String[] members;
int memberCount;
int[][] setMembership;

// derived data variables
int[] setCounts;
int[][] setFreq;
int[][][] setFreqOverlap;

// mark which permutations are selected or highlighted
boolean[][] selected;

// size and color of screen
int w = 800;
int h = 400;
color bg = color(255, 255, 255, 0);

// position and size of graph
int graphX = 100;
int graphY = 100;
int graphW = w - graphX * 2;
int graphH = h - graphY * 2;
int barS = 25;
int barW;
int barY = graphY + graphH;
int barMax;
int barMaxRelative;

// whether to display bars in relative mode
boolean relative = false;

// set colors
color[][] setColors;
color[] colors;
color[] colorsl;
color c0 = color(255, 121, 121);
color c1 = color(121, 121, 255);
color c2 = color(121, 255, 121);
color c3 = color(121, 121, 188);
color c4 = color(255, 188, 143);
color c5 = color(255, 255, 121);
color c6 = color(188, 148, 121);
color c7 = color(255, 121, 255);
color c0l = color(255, 180, 180);
color c1l = color(180, 180, 255);
color c2l = color(180, 255, 180);
color c3l = color(180, 180, 220);
color c4l = color(255, 220, 200);
color c5l = color(255, 255, 180);
color c6l = color(220, 200, 180);
color c7l = color(255, 180, 255);

// font data
PFont titleFont;
PFont dataFont;

// store hover time (in milliseconds)
float hoverTime;
float hoverWaitTime = 350;
boolean hoverTimeSet = false;

// initial setup
void setup(){
  size(800, 400, P2D);
  
  processData();
  
  // set up color storage
  colors = new color[8];
  colors[0] = c1;
  colors[1] = c2;
  colors[2] = c3;
  colors[3] = c4;
  colors[4] = c5;
  colors[5] = c6;
  colors[6] = c7;
  colors[7] = c0;
  colorsl = new color[8];
  colorsl[0] = c1l;
  colorsl[1] = c2l;
  colorsl[2] = c3l;
  colorsl[3] = c4l;
  colorsl[4] = c5l;
  colorsl[5] = c6l;
  colorsl[6] = c7l;
  colorsl[7] = c0l;
  
  // set fonts
  titleFont = createFont("Verdana", 20);
  dataFont = createFont("Georgia", 20);
}

// begin draw cycle
void draw(){
  // wipe background each time
  background(bg);
  
  // create proper selection colors
  for(int i = 0; i < setCount; i++){
    for(int j = 0; j < setCount; j++){
      int col = i % 8;
      if(selected[i][j])
        setColors[i][j] = colors[col];
      else
        setColors[i][j] = colorsl[col];
    }
  }
  
  // draw bar graph
  for(int i = 0; i < setCount; i++){
    fill(0, 0, 0, 35);
    stroke(255);
    strokeWeight(1);
    if(relative)
      barMaxRelative = setCounts[i];
    else
      barMaxRelative = barMax;
    for(int j = 0; j < setCount; j++)
      rect(graphX + (barS * (i + 1)) + (barW * i) + barW * j / setCount, graphY + graphH, barW / setCount, - (float) setCounts[i] / barMaxRelative * graphH);
    float prevY = 0;
    float nextY;
    for(int j = 0; j < setCount; j++){
      fill(setColors[i][j]);
      nextY = -(float) setFreq[i][j] / barMaxRelative * graphH;
      rect(graphX + (barS * (i + 1)) + (barW * i), graphY + graphH + prevY, barW * (setCount - j) / setCount, nextY);
      if(!selected[i][j]){
        for(int k = 0; k < setCount; k++){
          if(selected[k][j]){
            int col = i % 8;
            fill(colors[col]);
            float cnt = -(float) setFreqOverlap[k][j][i] / barMaxRelative * graphH;
            rect(graphX + (barS * (i + 1)) + (barW * i), graphY + graphH + prevY, barW *(setCount - j) / setCount, cnt);
          }
        }
      }
      prevY += nextY;
    }
  }
  
  // draw bar graph lines
  fill(0);
  stroke(0);
  line(graphX, graphY + graphH, graphX + graphW, graphY + graphH);
  line(graphX, graphY, graphX, graphY + graphH);
  
  // draw titles
  textFont(titleFont);
  textAlign(CENTER);
  String title = fileNames[data];
  text(title, w / 2, graphY - 50);
  textSize(12);
  String yAxisTitle = "members";
  pushMatrix();
  translate(graphX / 2, graphY + graphH / 2);
  rotate(-HALF_PI);
  text(yAxisTitle, 0, 0);
  popMatrix();
  for(int i = 0; i < setCount; i++)
    text(sets[i], graphX + (barS * (i + 1)) + (barW * i) + barW / 2, graphY + graphH + 50);
  
  // draw data marks
  textFont(dataFont);
  textSize(12);
  stroke(75);
  strokeWeight(1);
  textAlign(CENTER, TOP);
  if(relative)
    text("100%", graphX - 25, graphY);
  else
    text(barMax, graphX - 25, graphY);
  line(graphX - 10, graphY, graphX, graphY);
  textAlign(CENTER, BOTTOM);
  text("0", graphX - 25, graphY + graphH);
  line(graphX - 10, graphY + graphH, graphX, graphY + graphH);
  
  // hover over items
  if(pmouseX == mouseX && pmouseY == mouseY){
    if(!hoverTimeSet){
      hoverTime = millis();
      hoverTimeSet = true;
    }
    if(millis() - hoverTime > hoverWaitTime)
      onHover();
  }else{
    hoverTimeSet = false;
  }
}

// on hover over items
void onHover(){
  // hovering over sets
  if(mouseY > (graphY + graphH)){
    for(int i = 0; i < setCount; i++){
      int barX = graphX + (barS * (i + 1)) + (barW * i);
      if(mouseX > barX && mouseX < (barX + barW))
        overlayText(setCounts[i], mouseX, mouseY);
    }
  
  // hovering over blocks / permutations
  }else if(mouseY > graphY && mouseY < (graphY + graphH)){
    for(int i = 0; i < setCount; i++){
      int barX = graphX + (barS * (i + 1)) + (barW * i);
      if(mouseX > barX && mouseX < (barX + barW)){
        float prevY = 0;
        float nextY;
        int hover = 0;
        if(relative)
          barMaxRelative = setCounts[i];
        else
          barMaxRelative = barMax;
        for(int j = 0; j < setCount; j++){
          nextY = -(float) setFreq[i][j] / barMaxRelative * graphH;
          if(mouseY < (graphY + graphH + prevY) && mouseY > (graphY + graphH + prevY + nextY)){
            overlayText(setFreq[i][j], mouseX, mouseY);
            hover = j;
          }
          prevY += nextY;
        }
        // also color linked frequency count sets
        stroke(255);
        strokeWeight(1);
        for(int j = 0; j < setCount; j++){
          int col = j % 8;
          fill(colors[col]);
          prevY = 0;
          if(relative)
            barMaxRelative = setCounts[j];
          else
            barMaxRelative = barMax;
          for(int k = 0; k < setCount; k++){
            nextY = -(float) setFreq[j][k] / barMaxRelative * graphH;
            float cnt = -(float) setFreqOverlap[i][k][j] / barMaxRelative * graphH;
            if(k == hover && i != j)
              rect(graphX + (barS * (j + 1)) + (barW * j), graphY + graphH + prevY, barW * (setCount - hover) / setCount, cnt);
            prevY += nextY;
          }
        }
      }
    }
  }
}

// overlay text at cursor (tooltip)
void overlayText(int value, int x, int y){
  textFont(dataFont);
  textAlign(CENTER, CENTER);
  textSize(12);
  fill(255, 255, 255, 175);
  noStroke();
  rectMode(CENTER);
  rect(x - 15, y + 2, 30, 15);
  rectMode(CORNER);
  stroke(255);
  fill(0);
  text(value, x - 15, y);
}

// when selecting items
void mouseClicked(){
  // selecting sets (turn all on or all off)
  if(mouseY > (graphY + graphH)){
    for(int i = 0; i < setCount; i++){
      int barX = graphX + (barS * (i + 1)) + (barW * i);
      if(mouseX > barX && mouseX < (barX + barW)){
        int numSelected = 0;
        for(int j = 0; j < setCount; j++){
          if(selected[i][j])
            numSelected += 1;
        }
        for(int j = 0; j < setCount; j++){
          if(numSelected < setCount)
            selected[i][j] = true;
          else
            selected[i][j] = false;
        }
      }
    }
  
  // selecting blocks / permutations
  }else if(mouseY > graphY && mouseY < (graphY + graphH)){
    for(int i = 0; i < setCount; i++){
      int barX = graphX + (barS * (i + 1)) + (barW * i);
      if(mouseX > barX && mouseX < (barX + barW)){
        float prevY = 0;
        float nextY;
        if(relative)
          barMaxRelative = setCounts[i];
        else
          barMaxRelative = barMax;
        for(int j = 0; j < setCount; j++){
          nextY = -(float) setFreq[i][j] / barMaxRelative * graphH;
          if(mouseY < (graphY + graphH + prevY) && mouseY > (graphY + graphH + prevY + nextY)){
            if(selected[i][j])
              selected[i][j] = false;
            else
              selected[i][j] = true;
          }
          prevY += nextY;
        }
      }
    }
  
  // selecting y-axis, toggle relative mode
    if(mouseX < graphX){
      if(relative)
        relative = false;
      else
        relative = true;
    }
  
  // selecting to change the current data set
  }else if(mouseY < (graphY - 30) && mouseX > (w / 4) && mouseX < (w - w / 4)){
    if(mouseButton == LEFT)
      data = (data + 1) % fileNames.length;
    else if(mouseButton == RIGHT)
      data = (data + (fileNames.length - 1)) % fileNames.length;
    processData();
  }
}

// shortcuts / key commands
void keyTyped(){
  // 'r' or 'R' to toggle relative mode on or off
  if(int(key) == 114 || int(key) == 82){
    if(relative)
      relative = false;
    else
      relative = true;
  }
  
  // 'd' or 'D' to toggle between datasets
  if(int(key) == 100 || int(key) == 68){
    data = (data + 1) % fileNames.length;
    processData();
  }
}

// when importing and processing data into data storage variables
void processData(){
  // read in data
  String[] lines = loadStrings(fileLocation + fileNames[data] + extension);
  
  // for each line, parse through and store the raw, cleaned data
  memberCount = lines.length - 1;
  members = new String[memberCount];
  for(int i = 0; i < lines.length; i++){
    String[] pieces = split(lines[i], ",");
    
    // for header row
    if(i == 0){
      setCount = pieces.length - 1;
      sets = new String[setCount];
      setCounts = new int[setCount];
      setMembership = new int[memberCount][setCount];
      for(int j = 0; j < pieces.length; j++){
        if(j != 0){
          pieces[j] = split(pieces[j], "\"")[1];
          sets[j - 1] = pieces[j];
        }
      }
    
    // for non-header row
    }else{
      pieces[0] = trim(split(pieces[0], "\"")[1]);
      members[i - 1] = pieces[0];
      for(int j = 0; j < pieces.length; j++)
        if(j != 0)
          setMembership[i - 1][j - 1] = int(pieces[j]);
    }
  }
  
  // set bar width
  barW = (graphW - (barS * (setCount + 1))) / setCount;
  
  // count the total number of elements in each set, store max
  barMax = 0;
  for(int i = 0; i < memberCount; i++){
    for(int j = 0; j < setCount; j++){
      if(i == 0)
        setCounts[j] = 0;
      if(setMembership[i][j] > 0 && !sets[j].equals(oddData))
        setCounts[j] += 1;
      else if(setMembership[i][j] < 2 && sets[j].equals(oddData))
        setCounts[j] += 1;
      if(i == memberCount - 1)
        if(setCounts[j] > barMax)
          barMax = setCounts[j];
    }
  }
  
  // determine frequency counts among sets
  setFreq = new int[setCount][setCount];
  setFreqOverlap = new int[setCount][setCount][setCount];
  selected = new boolean[setCount][setCount];
  for(int i = 0; i < setCount; i++){
    // store frequency count
    for(int j = 0; j < memberCount; j++){
      // determine frequency
      int freq = 0;
      for(int k = 0; k < setCount; k++){
        // create initial selection
        selected[i][k] = false;
        // set initial frequency count to zero
        if(j == 0)
          setFreq[i][k] = 0;
        if(setMembership[j][k] > 0 && !sets[k].equals(oddData))
          freq += 1;
        else if(setMembership[j][k] < 2 && sets[k].equals(oddData))
          freq += 1;
      }
      // add to frequency count
      if(setMembership[j][i] > 0 && freq > 0 && !sets[i].equals(oddData))
        setFreq[i][freq - 1] += 1;
      else if(setMembership[j][i] < 2 && freq > 0 && sets[i].equals(oddData))
        setFreq[i][freq - 1] += 1;
      // associate this count to a specific set
      for(int k = 0; k < setCount; k++){
        if(j == 0)
          for(int l = 0; l < setCount; l++)
            setFreqOverlap[i][l][k] = 0;
        if(setMembership[j][k] > 0 && setMembership[j][i] > 0 && freq > 0 && !sets[k].equals(oddData) && !sets[i].equals(oddData))
          setFreqOverlap[i][freq - 1][k] += 1;
        else if(setMembership[j][k] > 0 && setMembership[j][i] < 2 && freq > 0 && !sets[k].equals(oddData) && sets[i].equals(oddData))
          setFreqOverlap[i][freq - 1][k] += 1;
        else if(setMembership[j][k] < 2 && setMembership[j][i] > 0 && freq > 0 && sets[k].equals(oddData) && !sets[i].equals(oddData))
          setFreqOverlap[i][freq - 1][k] += 1;
        else if(setMembership[j][k] < 2 && setMembership[j][i] < 2 && freq > 0 && sets[k].equals(oddData) && sets[i].equals(oddData))
          setFreqOverlap[i][freq - 1][k] += 1;
      }
    }
  }
  
  // set up color storage
  setColors = new color[setCount][setCount];
}