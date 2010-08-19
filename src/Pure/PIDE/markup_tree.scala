/*  Title:      Pure/PIDE/markup_tree.scala
    Author:     Fabian Immler, TU Munich
    Author:     Makarius

Markup trees over nested / non-overlapping text ranges.
*/

package isabelle


import javax.swing.tree.DefaultMutableTreeNode

import scala.collection.immutable.SortedMap
import scala.collection.mutable
import scala.annotation.tailrec


object Markup_Tree
{
  case class Node[A](val range: Text.Range, val info: A)
  {
    def contains[B](that: Node[B]): Boolean = this.range contains that.range
    def restrict(r: Text.Range): Node[A] = Node(range.restrict(r), info)
  }


  /* branches sorted by quasi-order -- overlapping intervals appear as equivalent */

  object Branches
  {
    type Entry = (Node[Any], Markup_Tree)
    type T = SortedMap[Node[Any], Entry]

    val empty = SortedMap.empty[Node[Any], Entry](new scala.math.Ordering[Node[Any]]
      {
        def compare(x: Node[Any], y: Node[Any]): Int = x.range compare y.range
      })

    def update(branches: T, entry: Entry): T = branches + (entry._1 -> entry)

    def overlapping(range: Text.Range, branches: T): T =
      branches.range(Node(range.start_range, Nil), Node(range.stop_range, Nil))
  }

  val empty = new Markup_Tree(Branches.empty)
}


case class Markup_Tree(val branches: Markup_Tree.Branches.T)
{
  import Markup_Tree._

  override def toString =
    branches.toList.map(_._2) match {
      case Nil => "Empty"
      case list => list.mkString("Tree(", ",", ")")
    }

  def + (new_node: Node[Any]): Markup_Tree =
  {
    branches.get(new_node) match {
      case None =>
        new Markup_Tree(Branches.update(branches, new_node -> empty))
      case Some((node, subtree)) =>
        if (node.range != new_node.range && node.contains(new_node))
          new Markup_Tree(Branches.update(branches, node -> (subtree + new_node)))
        else if (new_node.contains(branches.head._1) && new_node.contains(branches.last._1))
          new Markup_Tree(Branches.update(Branches.empty, (new_node -> this)))
        else {
          val body = Branches.overlapping(new_node.range, branches)
          if (body.forall(e => new_node.contains(e._1))) {
            val rest = (branches /: body) { case (bs, (e, _)) => bs - e }
            new Markup_Tree(Branches.update(rest, new_node -> new Markup_Tree(body)))
          }
          else { // FIXME split markup!?
            System.err.println("Ignored overlapping markup: " + new_node)
            this
          }
        }
    }
  }

  // FIXME depth-first with result markup stack
  // FIXME projection to given range
  def flatten(parent: Node[Any]): List[Node[Any]] =
  {
    val result = new mutable.ListBuffer[Node[Any]]
    var offset = parent.range.start
    for ((_, (node, subtree)) <- branches.iterator) {
      if (offset < node.range.start)
        result += new Node(Text.Range(offset, node.range.start), parent.info)
      result ++= subtree.flatten(node)
      offset = node.range.stop
    }
    if (offset < parent.range.stop)
      result += new Node(Text.Range(offset, parent.range.stop), parent.info)
    result.toList
  }

  def filter(pred: Node[Any] => Boolean): Markup_Tree =
  {
    val bs = branches.toList.flatMap(entry => {
      val (_, (node, subtree)) = entry
      if (pred(node)) List((node, (node, subtree.filter(pred))))
      else subtree.filter(pred).branches.toList
    })
    new Markup_Tree(Branches.empty ++ bs)
  }

  def select[A](range: Text.Range)(sel: PartialFunction[Any, A]): Stream[Node[List[A]]] =
  {
    def stream(parent: Node[List[A]], bs: Branches.T): Stream[Node[List[A]]] =
    {
      val substream =
        (for ((_, (node, subtree)) <- Branches.overlapping(parent.range, bs).toStream) yield {
          if (sel.isDefinedAt(node.info)) {
            val current = Node(node.range.restrict(parent.range), List(sel(node.info)))
            stream(current, subtree.branches)
          }
          else stream(parent, subtree.branches)
        }).flatten

      def padding(last: Text.Offset, s: Stream[Node[List[A]]]): Stream[Node[List[A]]] =
        s match {
          case (node @ Node(Text.Range(start, stop), _)) #:: rest =>
            if (last < start)
              parent.restrict(Text.Range(last, start)) #:: node #:: padding(stop, rest)
            else node #:: padding(stop, rest)
          case Stream.Empty =>
            if (last < parent.range.stop)
              Stream(parent.restrict(Text.Range(last, parent.range.stop)))
            else Stream.Empty
        }
      padding(parent.range.start, substream)
    }
    stream(Node(range, Nil), branches)
  }

  def swing_tree(parent: DefaultMutableTreeNode)(swing_node: Node[Any] => DefaultMutableTreeNode)
  {
    for ((_, (node, subtree)) <- branches) {
      val current = swing_node(node)
      subtree.swing_tree(current)(swing_node)
      parent.add(current)
    }
  }
}

