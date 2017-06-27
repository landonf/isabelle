/*  Title:      Pure/General/http.scala
    Author:     Makarius

HTTP server support.
*/

package isabelle


import java.net.{InetAddress, InetSocketAddress, URI, URLDecoder}
import com.sun.net.httpserver.{HttpExchange, HttpHandler, HttpServer}

import scala.collection.immutable.SortedMap


object HTTP
{
  /** server **/

  /* response */

  object Response
  {
    def apply(
        bytes: Bytes = Bytes.empty,
        content_type: String = "application/octet-stream"): Response =
      new Response(bytes, content_type)

    val empty: Response = apply()
    def text(s: String): Response = apply(Bytes(s), "text/plain; charset=utf-8")
    def html(s: String): Response = apply(Bytes(s), "text/html; charset=utf-8")
  }

  class Response private[HTTP](val bytes: Bytes, val content_type: String)
  {
    override def toString: String = bytes.toString
  }


  /* exchange */

  class Exchange private[HTTP](val http_exchange: HttpExchange)
  {
    def request_method: String = http_exchange.getRequestMethod
    def request_uri: URI = http_exchange.getRequestURI

    def read_request(): Bytes =
      using(http_exchange.getRequestBody)(Bytes.read_stream(_))

    def write_response(code: Int, response: Response)
    {
      http_exchange.getResponseHeaders().set("Content-Type", response.content_type)
      http_exchange.sendResponseHeaders(code, response.bytes.length.toLong)
      using(http_exchange.getResponseBody)(response.bytes.write_stream(_))
    }
  }


  /* handler */

  class Handler private[HTTP](val root: String, val handler: HttpHandler)
  {
    override def toString: String = root
  }

  def handler(root: String, body: Exchange => Unit): Handler =
    new Handler(root, new HttpHandler { def handle(x: HttpExchange) { body(new Exchange(x)) } })


  /* particular methods */

  sealed case class Arg(method: String, uri: URI, request: Bytes)
  {
    def decode_properties: Properties.T =
      Library.space_explode('&', request.text).map(s =>
        Library.space_explode('=', s) match {
          case List(a, b) =>
            URLDecoder.decode(a, UTF8.charset_name) ->
            URLDecoder.decode(b, UTF8.charset_name)
          case _ => error("Malformed key-value pair in HTTP/POST: " + quote(s))
        })
  }

  def method(name: String, root: String, body: Arg => Option[Response]): Handler =
    handler(root, http =>
      {
        val request = http.read_request()
        if (http.request_method == name) {
          val arg = Arg(name, http.request_uri, request)
          Exn.capture(body(arg)) match {
            case Exn.Res(Some(response)) =>
              http.write_response(200, response)
            case Exn.Res(None) =>
              http.write_response(404, Response.empty)
            case Exn.Exn(ERROR(msg)) =>
              http.write_response(500, Response.text(Output.error_message_text(msg)))
            case Exn.Exn(exn) => throw exn
          }
        }
        else http.write_response(400, Response.empty)
      })

  def get(root: String, body: Arg => Option[Response]): Handler = method("GET", root, body)
  def post(root: String, body: Arg => Option[Response]): Handler = method("POST", root, body)


  /* server */

  class Server private[HTTP](val http_server: HttpServer)
  {
    def += (handler: Handler) { http_server.createContext(handler.root, handler.handler) }
    def -= (handler: Handler) { http_server.removeContext(handler.root) }

    def start: Unit = http_server.start
    def stop: Unit = http_server.stop(0)

    def address: InetSocketAddress = http_server.getAddress
    def url: String = "http://" + address.getHostName + ":" + address.getPort
    override def toString: String = url
  }

  def server(handlers: List[Handler] = isabelle_resources): Server =
  {
    val localhost = InetAddress.getByName("127.0.0.1")
    val http_server = HttpServer.create(new InetSocketAddress(localhost, 0), 0)
    http_server.setExecutor(null)

    val server = new Server(http_server)
    for (handler <- handlers) server += handler
    server
  }



  /** Isabelle resources **/

  lazy val isabelle_resources: List[Handler] =
    List(welcome, fonts())


  /* welcome */

  val welcome: Handler =
    get("/", uri =>
      if (uri.toString == "/") {
        val id =
          Isabelle_System.getenv("ISABELLE_ID") match {
            case "" => Mercurial.repository(Path.explode("~~")).id()
            case id => id
          }
        Some(Response.text("Welcome to Isabelle/" + id + ": " + Distribution.version))
      }
      else None)


  /* fonts */

  private lazy val html_fonts: SortedMap[String, Bytes] =
    SortedMap(
      Isabelle_System.fonts(html = true).map(path => (path.base_name -> Bytes.read(path))): _*)

  def fonts(root: String = "/fonts"): Handler =
    get(root, uri =>
      {
        val uri_name = uri.toString
        if (uri_name == root) Some(Response.text(cat_lines(html_fonts.map(_._1))))
        else html_fonts.collectFirst({ case (a, b) if uri_name == root + "/" + a => Response(b) })
      })
}
