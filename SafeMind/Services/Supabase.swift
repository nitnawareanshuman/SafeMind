//
//  Supabase.swift
//  SafeMind
//
//  Central Supabase client configuration and dependency-injection entry point.
//

import Foundation
import Supabase

let supabase = SupabaseClient(
    supabaseURL: URL(string: "https://ubbmnrjvxctcygyowxag.supabase.co")!,
    supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InViYm1ucmp2eGN0Y3lneW93eGFnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ2MTA3NjgsImV4cCI6MjEwMDE4Njc2OH0.t7Na5cz6Ps1Bh35efsr9RCd30B_fT2hfxJp-GMBAhBQ"
)
