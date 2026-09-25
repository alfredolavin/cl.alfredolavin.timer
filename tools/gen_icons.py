#!/usr/bin/env python3
"""Generate contents/ui/code/icons.js and contents/icons/<codepoint>.svg from a Nerd Font.

The widget ships the SVGs, so no font needs to be installed to use it.
Requires fontTools (pip install fonttools). Usage:
    python3 tools/gen_icons.py [path/to/SomeNerdFont.ttf]
"""
import glob, json, os, re, shutil, subprocess, sys
from fontTools.ttLib import TTFont
from fontTools.pens.boundsPen import BoundsPen
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "contents", "ui", "code", "icons.js")
SVG_DIR = os.path.join(HERE, "..", "contents", "icons")
MAX_ICONS = 300
# used by the default timers in contents/ui/code/util.js and for new timers
REQUIRED = {"f051b", "f051f", "f0176", "f0d9e", "f0aaf", "f1160", "f01e6", "f117b", "f14f7"}

CATEGORIES = [
    ("Time", "timer timer_outline timer_sand timer_sand_complete alarm alarm_check alarm_bell alarm_multiple clock clock_outline clock_fast clock_alert clock_check clock_start clock_end hourglass av_timer calendar calendar_clock calendar_check history update sun_clock progress_clock camera_timer bell bell_ring bell_sleep weather_sunset weather_sunny weather_night"),
    ("Food & drink", "coffee coffee_outline coffee_maker coffee_to_go tea tea_outline cup cup_water glass_wine glass_mug glass_cocktail beer bottle_wine food food_apple food_croissant food_drumstick food_fork_drink food_hot_dog food_steak food_turkey food_variant hamburger pizza noodles pasta rice bread_slice cake cake_variant cupcake cookie egg egg_fried carrot fish cheese popcorn ice_cream candy muffin pot_steam pot_mix pot kettle kettle_steam stove toaster microwave fridge chef_hat silverware_fork_knife blender baguette corn fruit_cherries fruit_watermelon fruit_grapes fruit_pineapple fruit_citrus sausage bowl_mix taco french_fries grill"),
    ("Sports & fitness", "run run_fast walk hiking bike bike_fast swim dumbbell weight_lifter kettlebell yoga meditation jump_rope rowing skateboard ski ski_cross_country snowboard basketball soccer football tennis volleyball baseball golf bowling boxing_glove karate fencing badminton table_tennis trophy medal flag_checkered stairs shoe_sneaker heart_pulse arm_flex human_handsup human_greeting human_male human_female dance_ballroom dance_pole horse_human sail_boat kayaking surfing rugby cricket hockey_puck hockey_sticks whistle stopwatch"),
    ("Home & chores", "home home_outline sofa bed bed_king shower bathtub toilet broom vacuum washing_machine tumble_dryer iron dishwasher trash_can delete_empty recycle water_pump spray_bottle lightbulb lamp fan air_conditioner thermometer radiator fireplace door window_closed_variant key lock hammer screwdriver wrench saw_blade tools paint_roller format_paint brush watering_can flower sprout tree leaf grass shovel basket cart shopping tshirt_crew hanger sock baby_carriage cat dog paw fish_bowl bird car_wash"),
    ("Work & study", "laptop desktop_classic monitor keyboard mouse briefcase email email_outline phone cellphone message chat forum account_group presentation projector clipboard_text clipboard_check note_text notebook book book_open_variant book_open_page_variant library school pencil pen fountain_pen marker lead_pencil calculator chart_line chart_bar chart_pie file_document folder printer cloud_upload code_braces code_tags console bug git database server language_python language_javascript translate lightbulb_on brain head_cog target bullseye_arrow checkbox_marked_circle format_list_checks sticker_text_outline archive paperclip calendar_text timer_cog video_account headset microphone"),
    ("Health & self care", "heart heart_pulse pill medication needle hospital_box stethoscope tooth toothbrush face_man face_woman spa sleep power_sleep eye eye_off lungs water water_outline cup_water emoticon emoticon_happy emoticon_cool meditation hand_wash lotion shower_head bandage thermometer_lines weight scale_bathroom yoga hair_dryer content_cut lipstick glasses"),
    ("Media & fun", "music music_note headphones speaker radio play pause stop record_rec movie movie_open television gamepad_variant controller_classic dice_5 cards_playing puzzle chess_knight palette brush_variant camera image guitar_acoustic guitar_electric piano violin trumpet saxophone drum microphone_variant podcast youtube spotify book_music ticket party_popper balloon gift firework star_face emoticon_lol"),
    ("Nature & weather", "weather_sunny weather_cloudy weather_rainy weather_snowy weather_lightning weather_windy weather_fog weather_night weather_partly_cloudy snowflake umbrella fire water_drop leaf flower_tulip tree_outline pine_tree cactus mushroom butterfly bee ladybug fish turtle rabbit owl earth moon_waning_crescent white_balance_sunny waves volcano terrain image_filter_hdr island"),
    ("Travel & transport", "car bus train tram subway airplane airplane_takeoff ship_wheel ferry rocket rocket_launch motorbike scooter truck taxi gas_station ev_station parking map map_marker compass navigation earth_arrow_right bag_suitcase passport tent campfire bridge city office_building store hospital_building church mosque"),
    ("Actions", "play pause stop refresh reload sync restart autorenew check check_all close plus minus pencil delete content_save content_copy undo redo send share download upload magnify filter sort arrow_up arrow_down arrow_left arrow_right swap_horizontal rotate_right power lock_open login logout cog tune flash lightning_bolt rocket_launch bullhorn bell_ring flag bookmark pin star heart thumb_up hand_back_left fire gesture_tap cursor_default_click send_clock bike_fast run_fast broom washing_machine"),
]
FA_EXTRA = ["fa-mug_hot", "fa-person_running", "fa-person_walking", "fa-person_biking", "fa-person_swimming", "fa-dumbbell", "fa-bed", "fa-shower", "fa-utensils", "fa-carrot", "fa-bowl_food", "fa-seedling", "fa-hourglass_half", "fa-stopwatch", "fa-brain", "fa-book_open_reader", "fa-laptop_code", "fa-gamepad", "fa-guitar", "fa-paint_brush", "fa-baby", "fa-dog", "fa-cat", "fa-spa", "fa-pills", "fa-tooth", "fa-soap", "fa-pizza_slice", "fa-burger", "fa-ice_cream", "fa-lemon", "fa-pepper_hot", "fa-egg", "fa-bread_slice", "fa-fire_burner", "fa-kitchen_set", "fa-jug_detergent", "fa-person_praying", "fa-person_hiking", "fa-person_skating", "fa-person_skiing", "fa-table_tennis_paddle_ball", "fa-volleyball", "fa-headphones", "fa-microphone_lines", "fa-code", "fa-terminal", "fa-rocket", "fa-bolt", "fa-mug_saucer", "fa-wine_glass", "fa-champagne_glasses", "fa-cake_candles", "fa-cookie_bite", "fa-lightbulb", "fa-plant_wilt", "fa-leaf", "fa-bath"]


def find_font():
    if len(sys.argv) > 1:
        return sys.argv[1]
    out = subprocess.run(["fc-list", ":", "file", "family"], capture_output=True, text=True).stdout
    files = [l.split(":")[0] for l in out.splitlines() if "nerd" in l.lower()]
    files.sort(key=lambda f: ("Symbols" not in f, len(f)))
    if not files:
        sys.exit("No Nerd Font found")
    return files[0]


def svg_of(glyphs, name):
    """Glyph outline centered in a square viewBox (font units, y flipped), or None if empty."""
    bp = BoundsPen(glyphs)
    glyphs[name].draw(bp)
    if not bp.bounds:
        return None
    x0, y0, x1, y1 = bp.bounds
    side = max(x1 - x0, y1 - y0)
    pen = SVGPathPen(glyphs, ntos=lambda v: str(round(v)))
    glyphs[name].draw(TransformPen(pen, (1, 0, 0, -1, 0, 0)))
    vx = round(x0 - (side - (x1 - x0)) / 2)
    vy = round(-y1 - (side - (y1 - y0)) / 2)
    return ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="%d %d %d %d"><path d="%s"/></svg>\n'
            % (vx, vy, round(side), round(side), pen.getCommands()))


def main():
    font = find_font()
    tt = TTFont(font)
    glyphs = tt.getGlyphSet()
    by_name = {}
    for cp, name in tt.getBestCmap().items():
        if cp >= 0xE000:
            by_name.setdefault(name, cp)

    # candidates per category, in the order listed above
    per_cat, seen = [], set()
    groups = [(c, [("md-" + w, "md-" + w + "_outline", "fa-" + w) for w in ws.split()]) for c, ws in CATEGORIES]
    groups.append(("Font Awesome", [(n,) for n in FA_EXTRA]))
    for cat, words in groups:
        items = []
        for cands in words:
            for cand in cands:
                cp = by_name.get(cand)
                if cp and cp not in seen and svg_of(glyphs, cand):
                    seen.add(cp)
                    items.append([format(cp, "x"), cand, cat])
                    break
        per_cat.append(items)

    # icons used by the default timers are always kept, then categories take turns
    chosen = [i for items in per_cat for i in items if i[0] in REQUIRED]
    rest = [items[:] for items in per_cat]
    while len(chosen) < MAX_ICONS and any(rest):
        for items in rest:
            while items and items[0] in chosen:
                items.pop(0)
            if items and len(chosen) < MAX_ICONS:
                chosen.append(items.pop(0))
    order = {id(i): n for n, i in enumerate(i for items in per_cat for i in items)}
    chosen.sort(key=lambda i: order[id(i)])

    shutil.rmtree(SVG_DIR, ignore_errors=True)
    os.makedirs(SVG_DIR)
    for hexcp, name, _ in chosen:
        with open(os.path.join(SVG_DIR, hexcp + ".svg"), "w") as f:
            f.write(svg_of(glyphs, name))

    with open(OUT, "w") as f:
        f.write("// Generated by tools/gen_icons.py from %s. Do not edit.\n.pragma library\n\n" % os.path.basename(font))
        f.write("var categories = %s;\n\n" % json.dumps(["All"] + [c for c, _ in CATEGORIES] + ["Font Awesome"]))
        f.write("// [codepoint hex (= contents/icons/<hex>.svg), glyph name, category]\nvar icons = [\n")
        f.write(",\n".join(json.dumps(x) for x in chosen))
        f.write("\n];\n")
    print("font:", font, "icons:", len(chosen))


if __name__ == "__main__":
    main()
