/* Gina -- Virtual sticky notes
 * Copyright (C) 2006-2010  Andrea Bolognani <eof@kiyuko.org>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 *
 * Homepage: http://kiyuko.org/software/gina
 */

using GLib;


public class Gina.Note : Gtk.Window {

	/* Number of created notes: whenever this value reaches zero,
	 * the application is closed */
	private static int count = 0;

	/* Filename, or null if no file is associated with this note */
	private string filename;

	/* Whether the note's contents are different from the contents
	 * of the backing file */
	private bool changed;

	/* Widgets */
	private Gtk.Widget menu_bar;
	private Gtk.TextView text_view;

	construct {

		string menu_tree = "<ui>" +
		                   "  <menubar name=\"Menu\">" +
		                   "    <menu action=\"File\">" +
		                   "      <menuitem action=\"New\" />" +
		                   "      <menuitem action=\"Open\" />" +
		                   "      <separator />" +
		                   "      <menuitem action=\"Save\" />" +
		                   "      <menuitem action=\"SaveAs\" />" +
		                   "      <separator />" +
		                   "      <menuitem action=\"Close\" />" +
		                   "      <menuitem action=\"Quit\" />" +
		                   "    </menu>" +
		                   "    <menu action=\"Edit\">" +
		                   "      <menuitem action=\"Cut\" />" +
		                   "      <menuitem action=\"Copy\" />" +
		                   "      <menuitem action=\"Paste\" />" +
		                   "      <separator />" +
		                   "      <menuitem action=\"SelectAll\" />" +
		                   "    </menu>" +
		                   "    <menu action=\"View\">" +
		                   "      <menuitem action=\"ShowMenuBar\" />" +
		                   "      <menuitem action=\"ToggleDecorations\" />" +
		                   "    </menu>" +
		                   "    <menu action=\"Help\">" +
		                   "      <menuitem action=\"KeyBindings\" />" +
		                   "      <menuitem action=\"About\" />" +
		                   "    </menu>" +
		                   "  </menubar>" +
		                   "</ui>";

		title = "Gina";

		/* The window can't be resized under this size: it would be
		 * quite pointless to have a note on screen if it cannot
		 * display even a tiny amount of content */
		width_request = 70;
		height_request = 30;

		/* The window is this big by default */
		default_width = 200;
		default_height = 130;

		Gtk.Action action;
		Gtk.ToggleAction toggle_action;

		/* Load the menu definition */
		Gtk.UIManager menu = new Gtk.UIManager ();
		try {
			menu.add_ui_from_string (menu_tree, -1);
		}
		catch (Error e) {
			error ("%s\n", e.message);
		}

		Gtk.ActionGroup file_group = new Gtk.ActionGroup ("File");

		action = new Gtk.Action ("File", "_File", null, null);
		file_group.add_action (action);

		action = new Gtk.Action ("New", null, null, Gtk.STOCK_NEW);
		action.activate += () => {
			new Note ();
		};
		file_group.add_action_with_accel (action, "<Control>n");

		action = new Gtk.Action ("Open", null, null, Gtk.STOCK_OPEN);
		action.activate += () => {
			open ();
		};
		file_group.add_action_with_accel (action, "<Control>o");

		action = new Gtk.Action ("Save", null, null, Gtk.STOCK_SAVE);
		action.activate += () => {
			save ();
		};
		file_group.add_action_with_accel (action, "<Control>s");

		action = new Gtk.Action ("SaveAs", null, null, Gtk.STOCK_SAVE_AS);
		action.activate += () => {
			save_as ();
		};
		file_group.add_action_with_accel (action, "<Control><Shift>s");

		action = new Gtk.Action ("Close", null, null, Gtk.STOCK_CLOSE);
		action.activate += () => {
			close ();
		};
		file_group.add_action_with_accel (action, "<Control>w");

		action = new Gtk.Action ("Quit", null, null, Gtk.STOCK_QUIT);
		action.activate += () => {
			Gtk.main_quit ();
		};
		file_group.add_action_with_accel (action, "<Control>q");

		Gtk.ActionGroup edit_group = new Gtk.ActionGroup ("Edit");

		action = new Gtk.Action ("Edit", "_Edit", null, null);
		edit_group.add_action (action);

		action = new Gtk.Action ("Cut", null, null, Gtk.STOCK_CUT);
		action.activate += () => {
			text_view.cut_clipboard ();
		};
		edit_group.add_action_with_accel (action, "<Control>x");

		action = new Gtk.Action ("Copy", null, null, Gtk.STOCK_COPY);
		action.activate += () => {
			text_view.copy_clipboard ();
		};
		edit_group.add_action_with_accel (action, "<Control>c");
		action = new Gtk.Action ("Paste", null, null, Gtk.STOCK_PASTE);

		action.activate += () => {
			text_view.paste_clipboard ();
		};
		edit_group.add_action_with_accel (action, "<Control>v");

		action = new Gtk.Action ("SelectAll", null, null, Gtk.STOCK_SELECT_ALL);
		action.activate += () => {
			text_view.select_all (true);
		};
		edit_group.add_action_with_accel (action, "<Control>a");

		Gtk.ActionGroup view_group = new Gtk.ActionGroup ("View");

		action = new Gtk.Action ("View", "_View", null, null);
		view_group.add_action (action);

		toggle_action = new Gtk.ToggleAction ("ShowMenuBar", "Show _menubar", null, null);
		toggle_action.active = false;
		toggle_action.toggled += () => {
			if (menu_bar.visible) {
				menu_bar.hide ();
			}
			else {
				menu_bar.show_all ();
			}
		};
		view_group.add_action_with_accel (toggle_action, "<Control>m");

		toggle_action = new Gtk.ToggleAction ("ToggleDecorations", "Toggle _decorations", null, null);
		toggle_action.active = true;
		toggle_action.toggled += () => {
			if (decorated) {
				decorated = false;
			}
			else {
				decorated = true;
			}
		};
		view_group.add_action_with_accel (toggle_action, "<Control>d");

		Gtk.ActionGroup help_group = new Gtk.ActionGroup ("Help");

		action = new Gtk.Action ("Help", "_Help", null, null);
		help_group.add_action (action);

		action = new Gtk.Action ("KeyBindings", "Key _bindings", null, Gtk.STOCK_HELP);
		action.activate += () => {

			Gtk.Dialog dialog;
			Gtk.Label label;

			dialog = new Gtk.Dialog.with_buttons ("Key bindings",
			                                      this,
			                                      Gtk.DialogFlags.DESTROY_WITH_PARENT,
			                                      Gtk.STOCK_CLOSE,
			                                      Gtk.ResponseType.OK,
			                                      null);

			dialog.has_separator = false;
			dialog.border_width = 5;

			label = new Gtk.Label ("");
			label.set_markup ("<b>Manage notes</b>\n"+
			                  "Ctrl+N: Create new note\n" +
			                  "Ctrl+O: Load note from file\n" +
			                  "Ctrl+S: Save note\n" +
			                  "Shift+Ctrl+S: Save note as...\n" +
			                  "Ctrl+W: Close note\n" +
			                  "\n" +
			                  "<b>Edit</b>\n" +
			                  "Ctrl+C: Copy hilighted text\n" +
			                  "Ctrl+X: Cut text\n" +
			                  "Ctrl+V: Paste clipboard's contents\n" +
			                  "Ctrl+A: Select all\n" +
			                  "\n" +
			                  "<b>Miscellaneous</b>\n" +
			                  "Ctrl+M: Toggle menubar\n" +
			                  "Ctrl+D: Toggle window decorations\n" +
			                  "Ctrl+H: Show this help");
			dialog.vbox.add (label);

			dialog.show_all ();
			dialog.run ();
			dialog.destroy ();
		};
		help_group.add_action_with_accel (action, "<Control>h");

		action = new Gtk.Action ("About", null, null, Gtk.STOCK_ABOUT);
		action.activate += () => {
			Gtk.AboutDialog.set_url_hook ((dialog, link) => {
				try {
					Gtk.show_uri (this.get_screen (), link, Gdk.CURRENT_TIME);
				}
				catch (Error e) {
					warning ("Couldn't open link: %s", e.message);
				}
			});
			Gtk.show_about_dialog (this,
			                       "title", "About Gina",
			                       "program-name", "Gina",
			                       "version", "1.0.0",
			                       "website", "http://kiyuko.org/software/gina",
			                       "comments", "Virtual sticky notes",
			                       "copyright", "Copyright © 2006-2010 Andrea Bolognani",
			                       "authors", new string[] {"Andrea Bolognani <eof@kiyuko.org>", null});
		};
		help_group.add_action (action);

		menu.insert_action_group (file_group, 0);
		menu.insert_action_group (edit_group, 0);
		menu.insert_action_group (view_group, 0);
		menu.insert_action_group (help_group, 0);

		add_accel_group (menu.get_accel_group ());

		text_view = new Gtk.TextView ();
		text_view.buffer.changed += () => {

			changed = true;

			if (filename == null) {
				title = "* Gina";
			}
			else {
				title = "* Gina (" + filename + ")";
			}
		};

		/* Set some properties of the text view */
		text_view.left_margin = 3;
		text_view.right_margin = 3;
		text_view.wrap_mode = Gtk.WrapMode.WORD_CHAR;

		/* Set the background color */
		Gdk.Color color;
		Gdk.Color.parse ("#f9f3a9", out color);
		text_view.modify_base (Gtk.StateType.NORMAL, color);

		menu_bar = menu.get_widget ("/Menu");

		Gtk.VBox box = new Gtk.VBox (false, 0);
		box.pack_start (menu_bar, false, false, 0);
		box.pack_start (text_view, true, true, 0);
		add (box);

		/* The menu bar is hidden by default */
		box.show_all ();
		menu_bar.hide ();

		delete_event += (widget, event) => {
			close ();
		};

		/* XXX
		 * Would it be better not to show the note here, and to
		 * explicitly call show() when needed? */
		show ();

		count++;
	}

	public Note () {}

	private void open () {

		Gtk.FileChooserDialog open_dialog;

		string contents = "";
		bool success = true;

		open_dialog = new Gtk.FileChooserDialog ("Open...",
		                                         this,
		                                         Gtk.FileChooserAction.OPEN,
		                                         Gtk.STOCK_CANCEL,
		                                         Gtk.ResponseType.CANCEL,
		                                         Gtk.STOCK_OPEN,
		                                         Gtk.ResponseType.OK,
		                                         null);

		/* Allow only one local file to be selected */
		open_dialog.local_only = true;
		open_dialog.select_multiple = false;

		/* Repeat until either a file is selected, or the operation
		 * is cancelled by the user */
		do {

			int response = open_dialog.run ();

			if (response == Gtk.ResponseType.OK) {

				try {

					/* Get the contents of the selected file */
					FileUtils.get_contents (open_dialog.get_filename (), out contents);

					/* Make sure the file is encoded in UTF-8, since
					 * it's the only encoding we know how to handle */
					if (!contents.validate ()) {
						success = false;
					}

					/* Strip the trailing newline if present */
					if (contents.has_suffix ("\n")) {
						contents = contents.substring (0, contents.len () - 1);
					}

					success = true;
				}
				catch (FileError e) {

					Gtk.MessageDialog error_dialog;

					/* Show an error message, then let the user
					 * choose another file */
					error_dialog = new Gtk.MessageDialog (open_dialog,
					                                      Gtk.DialogFlags.MODAL,
					                                      Gtk.MessageType.ERROR,
					                                      Gtk.ButtonsType.OK,
					                                      e.message);
					error_dialog.run ();
					error_dialog.destroy ();

					success = false;
				}
			}

			/* The user cancelled the operation */
			else {
				success = false;
				break;
			}
		}
		while (!success);

		/* Change filename and set the text view's content */
		if (success) {
			filename = open_dialog.get_filename ();
			text_view.buffer.set_text (contents, -1);

			changed = false;
			title = "Gina (" + filename + ")";
		}

		open_dialog.destroy ();
	}

	private void close () {

		/* TODO
		 * Check if the note has been changed since
		 * loading/creation, and ask the user if he wants to save it */
		if (changed) {
			//debug ("Save changes?");
		}

		destroy ();

		count--;
		if (count == 0) {
			Gtk.main_quit ();
		}
	}

	private void save () {

		string contents;
		bool success = true;

		/* If the note has no file associated with it, the user must
		 * choose one */
		if (filename == null) {
			save_as ();
			return;
		}

		try {

			Gtk.TextIter start;
			Gtk.TextIter end;

			text_view.buffer.get_bounds (out start, out end);
			contents = text_view.buffer.get_text (start,
			                                      end,
			                                      false);

			/* Write to the selected file */
			FileUtils.set_contents (filename,
			                        contents + "\n",
			                        -1);
		}
		catch (FileError e) {

			Gtk.MessageDialog error_dialog;

			error_dialog = new Gtk.MessageDialog (this,
			                                      Gtk.DialogFlags.MODAL,
			                                      Gtk.MessageType.ERROR,
			                                      Gtk.ButtonsType.OK,
			                                      e.message);
			error_dialog.run ();
			error_dialog.destroy ();

			success = false;
		}

		if (success) {
			changed = false;
			title = "Gina (" + filename + ")";
		}
	}

	private void save_as () {

		Gtk.FileChooserDialog save_as_dialog;

		string contents;
		bool success = true;

		save_as_dialog = new Gtk.FileChooserDialog ("Save as...",
		                                            this,
		                                            Gtk.FileChooserAction.SAVE,
		                                            Gtk.STOCK_CANCEL,
		                                            Gtk.ResponseType.CANCEL,
		                                            Gtk.STOCK_OPEN,
		                                            Gtk.ResponseType.OK,
		                                            null);

		/* Allow only one local file to be selected */
		save_as_dialog.local_only = true;
		save_as_dialog.select_multiple = false;
		save_as_dialog.do_overwrite_confirmation = true;

		/* Repeat until either a file is selected, or the operation
		 * is cancelled by the user */
		do {

			int response = save_as_dialog.run ();

			if (response == Gtk.ResponseType.OK) {

				try {

					Gtk.TextIter start;
					Gtk.TextIter end;

					text_view.buffer.get_bounds (out start, out end);
					contents = text_view.buffer.get_text (start,
					                                      end,
					                                      false);

					/* Write to the selected file */
					FileUtils.set_contents (save_as_dialog.get_filename (),
					                        contents + "\n",
					                        -1);

					success = true;
				}
				catch (FileError e) {

					Gtk.MessageDialog error_dialog;

					/* Show an error message, then let the user
					 * choose another file */
					error_dialog = new Gtk.MessageDialog (save_as_dialog,
					                                      Gtk.DialogFlags.MODAL,
					                                      Gtk.MessageType.ERROR,
					                                      Gtk.ButtonsType.OK,
					                                      e.message);
					error_dialog.run ();
					error_dialog.destroy ();

					success = false;
				}
			}

			/* The user cancelled the operation */
			else {
				success = false;
				break;
			}
		}
		while (!success);

		/* Change filename and set the text view's content */
		if (success) {
			filename = save_as_dialog.get_filename ();
			changed = false;
			title = "Gina (" + filename + ")";
		}

		save_as_dialog.destroy ();
	}

	public static int main (string[] args) {

		Gtk.init (ref args);

		new Gina.Note ();

		Gtk.main ();
		return 0;
	}
}
