import std.stdio;

import diet.html;

static immutable string SOURCEPATH = "content/";

struct GlobalsImpl {
  string WebsiteName = "Barely Laughing";
}

immutable GlobalsImpl GLOBALS = GlobalsImpl();

struct Index {
  string heading;

  static Index parse(string path) {
    return Index("b5.re");
  }
}

struct Post {
  string title;
  string[] content;

  static Post parse(string path)
  {
    import std.file : readText;
    import std.string : splitLines;

    string[] parts = readText(path).splitLines;
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

void write_file(T, string TemplateFile)(string src_path, string basepath)
{
  import std.array : replace;
  import std.file : exists, mkdirRecurse, readText;
  import std.path : buildPath, dirName, setExtension;

  string path = buildPath(basepath, src_path).replace(SOURCEPATH, "");
  string dirs = path.dirName;

  if (!dirs.exists) {
    mkdirRecurse(dirs);
  }

  auto file = File(path.setExtension("html"), "wt");
  auto dest = file.lockingTextWriter;
  T ctx = T.parse(src_path);
  dest.compileHTMLDietFile!(TemplateFile, ctx, GLOBALS);
}

void main(string[] args)
{
  import std.file : exists, mkdir;

  // Sources for site go in content/
  // Output from build goes in build/
  // views/ is for diet templates

  string target = "build/";

  if (!target.exists) {
    target.mkdir;
  }

  string[] posts = get_posts(make_basepath("posts/"));

  foreach (post; posts) {
    write_file!(Post, "post.dt")(post, target);
  }

  write_file!(Index, "index.dt")(make_basepath("index.txt"), target);
}
