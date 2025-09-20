import React, { useState, useEffect } from 'react';
import './Notes.css';

const API_BASE = process.env.REACT_APP_API_URL || 'http://localhost:3001';

function Notes() {
  const [notes, setNotes] = useState([]);
  const [selectedNote, setSelectedNote] = useState(null);
  const [isEditing, setIsEditing] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [editForm, setEditForm] = useState({
    title: '',
    content: '',
    tags: []
  });

  // Load notes on component mount
  useEffect(() => {
    loadNotes();
  }, []);

  const loadNotes = async () => {
    try {
      setIsLoading(true);
      const response = await fetch(`${API_BASE}/api/notes`);
      const data = await response.json();
      
      if (data.success) {
        setNotes(data.data);
      }
    } catch (error) {
      console.error('Failed to load notes:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const createNote = async () => {
    try {
      const response = await fetch(`${API_BASE}/api/notes`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          title: 'New Note',
          content: '',
          tags: []
        }),
      });

      const data = await response.json();
      
      if (data.success) {
        setNotes(prev => [data.data, ...prev]);
        setSelectedNote(data.data);
        setEditForm({
          title: data.data.title,
          content: data.data.content,
          tags: data.data.tags || []
        });
        setIsEditing(true);
      }
    } catch (error) {
      console.error('Failed to create note:', error);
    }
  };

  const updateNote = async (noteId, updates) => {
    try {
      const response = await fetch(`${API_BASE}/api/notes/${noteId}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(updates),
      });

      const data = await response.json();
      
      if (data.success) {
        setNotes(prev => prev.map(note => 
          note.id === noteId ? data.data : note
        ));
        setSelectedNote(data.data);
        return data.data;
      }
    } catch (error) {
      console.error('Failed to update note:', error);
    }
  };

  const deleteNote = async (noteId) => {
    if (!window.confirm('Are you sure you want to delete this note?')) return;

    try {
      const response = await fetch(`${API_BASE}/api/notes/${noteId}`, {
        method: 'DELETE',
      });

      const data = await response.json();
      
      if (data.success) {
        setNotes(prev => prev.filter(note => note.id !== noteId));
        if (selectedNote?.id === noteId) {
          setSelectedNote(null);
          setIsEditing(false);
        }
      }
    } catch (error) {
      console.error('Failed to delete note:', error);
    }
  };

  const handleSaveNote = async () => {
    if (!selectedNote) return;

    const updated = await updateNote(selectedNote.id, editForm);
    if (updated) {
      setIsEditing(false);
    }
  };

  const handleSelectNote = (note) => {
    if (isEditing) {
      handleSaveNote();
    }
    
    setSelectedNote(note);
    setEditForm({
      title: note.title,
      content: note.content,
      tags: note.tags || []
    });
    setIsEditing(false);
  };

  const filteredNotes = notes.filter(note =>
    note.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
    note.content.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const formatDate = (dateString) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  return (
    <div className="notes">
      <div className="notes-sidebar">
        <div className="notes-header">
          <h2>Notes</h2>
          <button onClick={createNote} className="create-note-btn">
            ➕ New Note
          </button>
        </div>
        
        <div className="notes-search">
          <input
            type="text"
            placeholder="Search notes..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="search-input"
          />
        </div>

        <div className="notes-list">
          {isLoading ? (
            <div className="loading">Loading notes...</div>
          ) : filteredNotes.length === 0 ? (
            <div className="empty-state">
              {searchTerm ? 'No notes match your search' : 'No notes yet'}
            </div>
          ) : (
            filteredNotes.map((note) => (
              <div
                key={note.id}
                className={`note-item ${selectedNote?.id === note.id ? 'active' : ''}`}
                onClick={() => handleSelectNote(note)}
              >
                <div className="note-title">{note.title}</div>
                <div className="note-preview">
                  {note.content.substring(0, 100)}...
                </div>
                <div className="note-date">
                  {formatDate(note.updated_at)}
                </div>
                <button
                  onClick={(e) => {
                    e.stopPropagation();
                    deleteNote(note.id);
                  }}
                  className="delete-note-btn"
                  title="Delete note"
                >
                  🗑️
                </button>
              </div>
            ))
          )}
        </div>
      </div>

      <div className="notes-main">
        {selectedNote ? (
          <div className="note-editor">
            <div className="editor-header">
              {isEditing ? (
                <input
                  type="text"
                  value={editForm.title}
                  onChange={(e) => setEditForm(prev => ({ ...prev, title: e.target.value }))}
                  className="title-input"
                  placeholder="Note title..."
                />
              ) : (
                <h1 className="note-title">{selectedNote.title}</h1>
              )}
              
              <div className="editor-actions">
                {isEditing ? (
                  <>
                    <button onClick={handleSaveNote} className="save-btn">
                      💾 Save
                    </button>
                    <button 
                      onClick={() => {
                        setIsEditing(false);
                        setEditForm({
                          title: selectedNote.title,
                          content: selectedNote.content,
                          tags: selectedNote.tags || []
                        });
                      }}
                      className="cancel-btn"
                    >
                      ❌ Cancel
                    </button>
                  </>
                ) : (
                  <button onClick={() => setIsEditing(true)} className="edit-btn">
                    ✏️ Edit
                  </button>
                )}
              </div>
            </div>

            <div className="editor-content">
              {isEditing ? (
                <textarea
                  value={editForm.content}
                  onChange={(e) => setEditForm(prev => ({ ...prev, content: e.target.value }))}
                  className="content-editor"
                  placeholder="Start writing your note..."
                />
              ) : (
                <div className="content-display">
                  {selectedNote.content || 'This note is empty. Click Edit to add content.'}
                </div>
              )}
            </div>

            <div className="note-metadata">
              <span>Created: {formatDate(selectedNote.created_at)}</span>
              <span>Updated: {formatDate(selectedNote.updated_at)}</span>
            </div>
          </div>
        ) : (
          <div className="no-note-selected">
            <div className="empty-icon">📝</div>
            <h3>Select a note to view</h3>
            <p>Choose a note from the sidebar or create a new one to get started.</p>
          </div>
        )}
      </div>
    </div>
  );
}

export default Notes;