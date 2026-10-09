.pragma library

// A value as one shell word, safe inside any command line: 'it'\''s'
function quote(v) {
    return "'" + String(v).replace(/'/g, "'\\''") + "'";
}
