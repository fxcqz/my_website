import std.stdio;

import diet.html;

// TODO load globals from file
// TODO add bird log
// TODO add cool links
// TODO sort posts by date modified and add that to post content
// TODO add overflow-y to styling for some sections on index (??)
// TODO support code markup

static immutable string SOURCEPATH = "content/";
static immutable string TARGETPATH = "build/";

struct GlobalsImpl
{
  string WebsiteName = "Barely Laughing";
}

immutable GlobalsImpl GLOBALS = GlobalsImpl();

struct Page(T) {
  T obj;
  string url;
}

mixin template Register(T)
{
  static Page!(T)[] objs;
  static bool parsed = false;
}

struct Index
{
  string heading;
  Page!(Post)[] posts;

  static Index parse(string path)
  in (Post.parsed)
  {
    return Index("b5.re", Post.objs);
  }
}

struct Post
{
  string title;
  string[] content;

  mixin Register!Post;

  static Post parse(string path)
  in (!Post.parsed)
  out (; Post.parsed)
  {
    import std.file : readText;
    import std.string : splitLines;

    string[] parts = readText(path).splitLines;
    Post.parsed = true;

    return Post(parts[0], parts[1 .. $]);
  }
}

string[] get_posts(string basepath)
{
  import std.array : array;
  import std.algorithm : map, uniq;
  import std.conv : to;
  import std.file : dirEntries, SpanMode;

  return basepath.dirEntries(SpanMode.breadth).map!(to!string).uniq.array;
}

string make_basepath(string suffix)
{
  import std.path : buildPath;
  return buildPath(SOURCEPATH, suffix);
}

void write_file(T, string TemplateFile)(string src_path)
{
  import std.array : replace;
  import std.file : exists, mkdirRecurse, readText;
  import std.path : buildPath, dirName, setExtension;

  string path = buildPath(TARGETPATH, src_path).replace(SOURCEPATH, "").setExtension("html");
  string dirs = path.dirName;

  if (!dirs.exists) {
    mkdirRecurse(dirs);
  }

  auto file = File(path, "wt");
  auto dest = file.lockingTextWriter;
  T ctx = T.parse(src_path);
  dest.compileHTMLDietFile!(TemplateFile, ctx, GLOBALS);

  static if (__traits(hasMember, T, "objs")) {
    // register this page instance so it can be referenced elsewhere
    T.objs ~= Page!T(ctx, path.replace(TARGETPATH, ""));
  }
}

void write_static()
{
  import std.file : copy, dirEntries, exists, mkdirRecurse, SpanMode;
  import std.path : baseName, buildPath, dirName;

  string src_css_path = buildPath(SOURCEPATH, "css", "main.css");
  if (src_css_path.exists) {
    string target_css_path = buildPath(TARGETPATH, "css", "main.css");
    mkdirRecurse(dirName(target_css_path));
    copy(src_css_path, target_css_path);
  }

  string src_img_path = buildPath(SOURCEPATH, "images");
  if (src_img_path.exists) {
    string target_img_path = buildPath(TARGETPATH, "images");
    mkdirRecurse(target_img_path);
    foreach (img; src_img_path.dirEntries(SpanMode.breadth)) {
      copy(img, buildPath(target_img_path, baseName(img)));
    }
  }
}

void main(string[] args)
{
  import std.file : exists, mkdir;

  // Sources for site go in content/
  // Output from build goes in build/
  // views/ is for diet templates

  if (!TARGETPATH.exists) {
    TARGETPATH.mkdir;
  }

  foreach (post; get_posts(make_basepath("posts/"))) {
    write_file!(Post, "post.dt")(post);
  }

  write_file!(Index, "index.dt")(make_basepath("index.txt"));
  write_static();
}
