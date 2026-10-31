#!/usr/bin/env python3
"""Pre-merge Xiaomi's mixer path overlays into the common mixer paths file.

Xiaomi's PAL layers mixer_paths_overlay_static.xml and
mixer_paths_overlay_dynamic.xml over the common file at runtime. The
source-built PAL (and AOSP audio_route, which rejects duplicate path names)
doesn't, so the overlays are folded in here instead.

  merge_mixer_overlay.py BASE OUT [--replace STATIC.xml] [--update DYNAMIC.xml]

--replace (static overlay), following the rules in that file's header:
  * top-level default <ctl>s override the same ctl in BASE (or are added)
  * a first-level <path> replaces the BASE path of the same name
  * paths absent from BASE are appended (the header says not to create any)

--update (dynamic overlay): its paths only carry the handful of controls to
  tweak (the headphones path has volumes and no routing), so replacing a path
  would drop its routing. Controls are overridden in place inside the existing
  path, or appended to it. Top-level defaults override as above.
"""
import re
import sys
import xml.etree.ElementTree as ET

PATH_RE = re.compile(r'^    <path name="([^"]+)">\n(.*?)^    </path>\n', re.S | re.M)
CTL_RE = re.compile(r'^( *)<ctl ([^>]*?)/>\n', re.M)


def read(p):
    t = open(p, encoding='latin-1').read()
    ET.fromstring(t.encode('latin-1'))
    return t


def key(attrs):
    a = dict(re.findall(r'(\w+)="([^"]*)"', attrs))
    return (a.get('name'), a.get('id'), a.get('index'))


def split_head(t):
    """-> (text before the first <path>, rest). Top-level default ctls live in the head."""
    m = PATH_RE.search(t)
    return (t[:m.start()], t[m.start():]) if m else (t, '')


def paths_of(t):
    return [(m.group(1), m.group(0)) for m in PATH_RE.finditer(t)]


def merge_ctls(head, ovl_head, stats):
    for m in CTL_RE.finditer(ovl_head):
        k, line = key(m.group(2)), m.group(0)
        done = [False]

        def sub(mm):
            if not done[0] and key(mm.group(2)) == k:
                done[0] = True
                stats['ctl_replaced'] += 1
                return line
            return mm.group(0)

        head = CTL_RE.sub(sub, head)
        if not done[0]:
            head = head.rstrip('\n') + '\n' + line + '\n'
            stats['ctl_added'] += 1
    return head


def apply_replace(base, ovl, stats):
    bh, rest = split_head(base)
    oh, _ = split_head(ovl)
    bh = merge_ctls(bh, oh, stats)
    over = dict(paths_of(ovl))
    seen = set()

    def rep(m):
        n = m.group(1)
        if n in over and n not in seen:
            seen.add(n)
            stats['path_replaced'] += 1
            return over[n]
        return m.group(0)

    rest = PATH_RE.sub(rep, rest)
    missing = [n for n, _ in paths_of(ovl) if n not in seen]
    if missing:
        stats['path_appended'] += missing
        rest = rest.replace('</mixer>', ''.join('\n' + over[n] for n in missing) + '</mixer>')
    return bh + rest


def apply_update(base, ovl, stats):
    bh, rest = split_head(base)
    oh, _ = split_head(ovl)
    bh = merge_ctls(bh, oh, stats)
    over = dict(paths_of(ovl))
    seen = set()

    def upd(m):
        n = m.group(1)
        if n not in over or n in seen:
            return m.group(0)
        seen.add(n)
        inner = m.group(2)
        for c in CTL_RE.finditer(PATH_RE.match(over[n]).group(2)):
            k, line = key(c.group(2)), c.group(0)
            hit = [False]

            def sub(mm):
                if not hit[0] and key(mm.group(2)) == k:
                    hit[0] = True
                    stats['pathctl_replaced'] += 1
                    return line
                return mm.group(0)

            inner = CTL_RE.sub(sub, inner)
            if not hit[0]:
                inner += line
                stats['pathctl_added'] += 1
        return '    <path name="%s">\n%s    </path>\n' % (n, inner)

    rest = PATH_RE.sub(upd, rest)
    stats['path_missing'] += [n for n in over if n not in seen]
    return bh + rest


def main(argv):
    if len(argv) < 3:
        sys.exit(__doc__)
    base_p, out_p = argv[:2]
    opts = argv[2:]
    base = read(base_p)
    stats = dict(ctl_replaced=0, ctl_added=0, path_replaced=0, path_appended=[],
                 pathctl_replaced=0, pathctl_added=0, path_missing=[])
    i = 0
    while i < len(opts):
        mode, p = opts[i], opts[i + 1]
        if mode == '--replace':
            base = apply_replace(base, read(p), stats)
        elif mode == '--update':
            base = apply_update(base, read(p), stats)
        else:
            sys.exit('unknown option ' + mode)
        i += 2
    ET.fromstring(base.encode('latin-1'))
    open(out_p, 'w', encoding='latin-1').write(base)
    print(stats)


if __name__ == '__main__':
    main(sys.argv[1:])
