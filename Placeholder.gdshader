shader_type canvas_item;

// Variablen, die wir von außen (Inspector oder Script) ändern können
uniform vec4 line_color : source_color = vec4(0.50, 0.50, 0.0, 1.0); // Weiß
uniform float line_thickness : hint_range(0.0, 1.0) = 0.00; // 0 ist aus

void fragment() {
    vec4 col = texture(TEXTURE, UV);
	
	if (line_thickness == 0.0){
	
		COLOR = col;	
	}
	else
	{
		
	
	
    vec2 size = TEXTURE_PIXEL_SIZE * line_thickness;
    
    // Wir prüfen die Transparenz der Nachbarpixel
    float au = texture(TEXTURE, UV + vec2(0, -size.y)).a;
    float ad = texture(TEXTURE, UV + vec2(0, size.y)).a;
    float al = texture(TEXTURE, UV + vec2(-size.x, 0)).a;
    float ar = texture(TEXTURE, UV + vec2(size.x, 0)).a;
    
    // Logik: Wenn der aktuelle Pixel sichtbar ist, aber einer seiner Nachbarn 
    // fast unsichtbar ist, sind wir am Rand!
    float outline = (1.0 - al * ar * au * ad);
    
    // Nur zeichnen, wenn der Originalpixel nicht komplett leer ist
    if (col.a > 0.05) {
        COLOR = mix(col, line_color, outline);
    } else {
        COLOR = col;
    }
	
	size = TEXTURE_PIXEL_SIZE * line_thickness;
	
	// Wir prüfen die Nachbarpixel (Oben, Unten, Links, Rechts)
	outline = texture(TEXTURE, UV + vec2(-size.x, 0)).a;
	outline += texture(TEXTURE, UV + vec2(size.x, 0)).a;
	outline += texture(TEXTURE, UV + vec2(0, -size.y)).a;
	outline += texture(TEXTURE, UV + vec2(0, size.y)).a;
	outline = min(outline, 1.0);
	
	vec4 color = texture(TEXTURE, UV);
	// Mische die Originalfarbe mit der Outline-Farbe basierend auf der Transparenz
	COLOR = mix(color, line_color, outline - color.a);
	//vec4 color = texture(TEXTURE, UV);
    
    // Wir prüfen, ob die UV-Koordinate nah am Rand (0.0 oder 1.0) liegt
    //if (UV.x < line_thickness || UV.x > 1.0 - line_thickness || UV.y < line_thickness || UV.y > 1.0 - line_thickness) {
      //  COLOR = line_color;
    //} else {
      //  COLOR = color;
    //}
	}
}