/*  Title:      Pure/System/cygwin.scala
    Author:     Makarius

Accessing the Cygwin installation.
*/

package isabelle

import java.lang.reflect.Method
import java.io.File


object Cygwin
{
  /* registry access */

  // Some black magic involving private WindowsPreferences from Sun, cf.
  // http://www.docjar.com/html/api/java/util/prefs/WindowsPreferences.java.html

  private val WindowsPreferences = Class.forName("java.util.prefs.WindowsPreferences")

  private val HKEY_CURRENT_USER = 0x80000001
  private val HKEY_LOCAL_MACHINE = 0x80000002
  private val KEY_READ = 0x20019
  private val NATIVE_HANDLE = 0
  private val ERROR_CODE = 1

  private def C_string(s: String): Array[Byte] =
    (s + "\0").getBytes("US-ASCII")

  private def J_string(bs: Array[Byte]): String =
    new String(bs, 0, bs.length - 1, "US-ASCII")

  private val INT = Integer.TYPE
  private val BYTES = (new Array[Byte](0)).getClass

  private def open_key(handle: Int, subkey: Array[Byte], mask: Int): Array[Int] =
  {
    val m = WindowsPreferences.getDeclaredMethod("WindowsRegOpenKey", INT, BYTES, INT)
    m.setAccessible(true)
    m.invoke(null, handle.asInstanceOf[Object], subkey.asInstanceOf[Object],
      mask.asInstanceOf[Object]).asInstanceOf[Array[Int]]
  }

  private def close_key(handle: Int): Int =
  {
    val m = WindowsPreferences.getDeclaredMethod("WindowsRegCloseKey", INT)
    m.setAccessible(true)
    m.invoke(null, handle.asInstanceOf[Object]).asInstanceOf[Int]
  }

  private def query(handle: Int, name: Array[Byte]) =
  {
    val m = WindowsPreferences.getDeclaredMethod("WindowsRegQueryValueEx", INT, BYTES)
    m.setAccessible(true)
    m.invoke(null, handle.asInstanceOf[Object], name.asInstanceOf[Object]).
      asInstanceOf[Array[Byte]]
  }

  def query_registry(sys: Boolean, path: String, name: String): Option[String] =
  {
    val handle = if (sys) HKEY_LOCAL_MACHINE else HKEY_CURRENT_USER
    val result = open_key(handle, C_string(path), KEY_READ)
    if (result(ERROR_CODE) != 0) None
    else {
      val res = query(result(NATIVE_HANDLE), C_string(name))
      if (res == null) None
      else Some(J_string(res))
    }
  }

  def query_registry(path: String, name: String): Option[String] =
    query_registry(false, path, name) orElse
      query_registry(true, path, name)


  /* Cygwin installation */

  // old-style mount points (Cygwin 1.5)
  private val CYGWIN_MOUNTS = "Software\\Cygnus Solutions\\Cygwin\\mounts v2"

  // new-style setup (Cygwin 1.7)
  private val CYGWIN_SETUP1 = "Software\\Cygwin\\setup"
  private val CYGWIN_SETUP2 = "Software\\Wow6432Node\\Cygwin\\setup"  // !?

  def config(): (String, String) =
  {
    query_registry(CYGWIN_SETUP1, "rootdir") match {
      case Some(root) => (root, "/cygdrive")
      case None =>
        val root =
          query_registry(CYGWIN_MOUNTS + "\\/", "native") getOrElse "C:\\cygwin"
        val cygdrive =
          query_registry(CYGWIN_MOUNTS, "cygdrive prefix") getOrElse "cygdrive"
        (root, cygdrive)
    }
  }


  /* basic sanity check */

  def check(root: String): Boolean =
    new File(root + "\\bin\\bash.exe").isFile &&
    new File(root + "\\bin\\env.exe").isFile
}

