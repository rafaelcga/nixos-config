final: prev: {
  ananicy-cpp = prev.ananicy-cpp.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      (final.fetchpatch2 {
        name = "fix-glibc-2.42-headers.patch";
        url = "https://gitlab.com/ananicy-cpp/ananicy-cpp/-/commit/3554447c1ca495478bd00e002078847dfd2205d6.patch";
        hash = "";
      })
    ];
  });
}
