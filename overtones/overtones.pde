import krister.Ess.*;

Silence silence;
float fundamental = 50.;
int tone_count = 10;
SineWave [] tones;
AudioStream output;
float [] buffer;
boolean phasing;

int wave_width = 384;
int box_x = wave_width + 100;
int box_w = 640 - box_x;
float slider_h = float(480) / tone_count;
int selected_slider_id;
boolean shift_down;

void setup() {
  size(640, 480);
  frameRate(30);
  Ess.start(this);
  silence = new Silence();
  tones = new SineWave[tone_count];
  float freq = fundamental;
  for (int i = 0; i < tone_count; i++) {
    tones[i] = new SineWave(freq, 0.0);
    freq += fundamental;
  }
  output = new AudioStream();
  output.start();
  buffer = null;
  phasing = true;
  selected_slider_id = -1;
  shift_down = false;
}

void draw() {
  background(255);
  stroke(0);
  if (buffer == null) return;
  float step = float(buffer.length) / wave_width / 2; // stretch it out by 2
  int x1 = 50;
  float y1 = 240;
  for (int i = 0; i < wave_width; i++) {
    int x = x1 + 1;
    float y = buffer[int(i * step)] * 100 + 240;
    line(x1, y1, x, y);
    x1 = x;
    y1 = y;
  }
  noStroke();
  fill(#ff0000, 63);
  rect(box_x, 0, box_w, height);
  stroke(0, 100);
  for (int i = 0; i < tone_count; i++) {
    line(box_x, (i + 1) * slider_h, width, (i + 1) * slider_h);
  }
  noStroke();
  fill(#005555);
  for (int i = 0; i < tone_count; i++) {
    float slider_value = tones[i].volume;
    int slider_x = box_x + int(slider_value * box_w);
    int slider_y = int(i * slider_h);
    rect(slider_x - 2, slider_y + 1, 5, slider_h - 2);
  }
}

void mousePressed() {
  int box_x = wave_width + 100;
  println("hi");
  for (int i = 0; i < tone_count; i++) {
    float slider_value = tones[i].volume;
    int slider_x = box_x + int(slider_value * box_w);
    int slider_y = int(i * slider_h);
    if (abs(mouseX - slider_x) <= 2) {
      if (mouseY >= slider_y && mouseY < slider_y + slider_h) {
        selected_slider_id = i;
        break;
      }
    }
  }
}

void mouseReleased() {
  selected_slider_id = -1;
}

void mouseDragged() {
  if (selected_slider_id >= 0) {
    if (shift_down) {
      tones[selected_slider_id].phase += mouseX - pmouseX;
    } else {
      float pixel_value = 1.0 / box_w;
      float value_change = pixel_value * (mouseX - pmouseX);
      tones[selected_slider_id].volume += value_change;
      if (tones[selected_slider_id].volume < 0.) {
        tones[selected_slider_id].volume = 0.;
      } else if (tones[selected_slider_id].volume > 1.) {
        tones[selected_slider_id].volume = 1.;
      }
    }
  }
}

void keyPressed() {
  if (key == CODED && keyCode == SHIFT) {
    shift_down = true;
  } else if (key == ' ') {
    phasing = !phasing;
  }
}

void keyReleased() {
  if (key == CODED && keyCode == SHIFT) {
    shift_down = false;
  }
}

void audioStreamWrite(AudioStream stream) {
  buffer = stream.buffer;
  silence.generate(stream);
  for (int i = 0; i < tone_count; i++) {
    tones[i].generate(stream, Ess.ADD);
    if (phasing) {
      tones[i].phase += stream.size;
      tones[i].phase %= stream.sampleRate;
    }
  }
}

public void stop() {
  Ess.stop();
  super.stop();
}
