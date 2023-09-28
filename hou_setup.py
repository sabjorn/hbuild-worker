## https://www.sidefx.com/docs/houdini/hom/commandline.html
def enableHouModule():
    import sys, os

    if hasattr(sys, "setdlopenflags"):
        old_dlopen_flags = sys.getdlopenflags()
        sys.setdlopenflags(old_dlopen_flags | os.RTLD_GLOBAL)

    try:
        import hou
    except ImportError:
        # If the hou module could not be imported, then add 
        # $HFS/houdini/pythonX.Ylibs to sys.path so Python can locate the
        # hou module.
        sys.path.append(os.environ['HHP'])
        import hou
    finally:
        # Reset dlopen flags back to their original value.
        if hasattr(sys, "setdlopenflags"):
            sys.setdlopenflags(old_dlopen_flags)

enableHouModule()

