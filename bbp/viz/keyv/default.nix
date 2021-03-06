{ stdenv, boost, fetchgit, cmake, leveldb, lunchbox, pression }:

stdenv.mkDerivation rec {
  name = "keyv-${version}";
  version = "1.1.0";

  buildInputs = [ stdenv boost cmake lunchbox leveldb pression ];

  src = fetchgit {
    url = "https://github.com/BlueBrain/Keyv.git";
    rev = "7951173";
    sha256 = "0kwyh58xbz99gc5c1j5mkvkn0p8y2gkf0l5pjz5ai28rps3ss2m6";
  };
  
  enableParallelBuilding = true;

  propagatedBuildInputs = [ lunchbox leveldb pression ];
  
}



