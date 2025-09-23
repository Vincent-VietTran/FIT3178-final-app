//
//  RecipeSearchingTableViewController.swift
//  FIT3178-final-app
//
//  Created by Viet Tran on 23/9/2025.
//

import UIKit

class SearchRecipesTableViewController: UITableViewController, UISearchBarDelegate {
    // Properties
    let CELL_RECIPE = "recipeCell"
    let NUM_SECTIONS = 1

    // array of RecipeData objects displayed to user
    var newRecipes = [RecipeData]()

    // Indicator for loading
    var indicator = UIActivityIndicatorView()

    // --- Letter-batch pagination state (TheMealDB has no startIndex/maxResults) ---
    private let lettersForBatches: [Character] = Array("abcdefghijklmnopqrstuvwxyz")
    private var currentLetterIndex: Int = 0
    private let letterBatchSize: Int = 3 // how many letters to fetch per batch
    private var seenRecipeIds: Set<String> = []
    private var isFetchingLetterBatch: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()

        // Search bar controller init
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.delegate = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false

        // Add a loading indicator view
        indicator.style = UIActivityIndicatorView.Style.large
        indicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(indicator)
        NSLayoutConstraint.activate([
            indicator.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor)
        ])

        // Start initial letter-batch load so user sees content even if they don't type
        indicator.startAnimating()
        Task {
            await requestRecipesNamed("") // empty string triggers letter-batch loading
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return NUM_SECTIONS
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return newRecipes.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: CELL_RECIPE, for: indexPath)
        let recipe = newRecipes[indexPath.row]
        cell.textLabel?.text = recipe.recipeName
        cell.detailTextLabel?.text = recipe.category

        return cell
    }

    // MARK: - API request call (supports letter-batch and name search)
    //
    // Asynchronously requests recipes from TheMealDB. This single method handles two
    // modes of operation:
    //  1) Letter-batch mode (when `recipeName` is empty): fetches a small batch of
    //     letters (e.g. "a", "b", "c") using `search.php?f=` and appends results to
    //     `newRecipes` while deduplicating by `seenRecipeIds`.
    //  2) Name/search mode (when `recipeName` is non-empty): uses `search.php?s=` for
    //     full-name queries, or `search.php?f=` when the query is a single character.
    // The method updates UI state (activity indicator and table view) on the main thread.
    //
    // Notes:
    //  - This method is async and should be called from an async context (or Task).
    //  - TheMealDB returns top-level JSON { "meals": [...] } or { "meals": null }.
    //    Ensure your top-level wrapper (`RecipeResponse`) maps `recipes` to `meals`.
    //  - Keep network / decoding work off the main thread; UI updates must be on main.
    func requestRecipesNamed(_ recipeName: String) async {
        // Print the incoming query and current batch index for debugging.
        print("Search text in request recipe named '\(recipeName)'")
        print("Current letter index \(currentLetterIndex)")

        // Trim whitespace/newlines from the incoming query.
        let trimmedQuery = recipeName.trimmingCharacters(in: .whitespacesAndNewlines)

        // -------------------------
        // LETTER-BATCH (default) MODE
        // Triggered when the search query is empty. This performs a small "batch" of
        // first-letter searches (search.php?f={letter}) to progressively populate the UI.
        // -------------------------
        if trimmedQuery.isEmpty {
            // Prevent concurrent batch loads: if a batch is in-flight, return immediately.
            if isFetchingLetterBatch { return }
            isFetchingLetterBatch = true

            // Start the activity indicator on the main thread so the UI shows progress.
            DispatchQueue.main.async { self.indicator.startAnimating() }

            // If we've already processed all letters, stop the indicator and return.
            guard currentLetterIndex < lettersForBatches.count else {
                DispatchQueue.main.async { self.indicator.stopAnimating() }
                isFetchingLetterBatch = false
                return
            }

            // Compute the slice of letters to request in this batch and advance the index.
            let start = currentLetterIndex
            let end = min(currentLetterIndex + letterBatchSize, lettersForBatches.count)
            let slice = lettersForBatches[start..<end]
            currentLetterIndex = end

            // Accumulate decoded RecipeData objects here before updating the UI.
            var gathered: [RecipeData] = []

            // For each letter in the batch, build the URL and perform the network request.
            // Note: we perform these sequentially to keep the load light; you can
            // parallelize with TaskGroup if desired, but be mindful of API rate limits.
            for letter in slice {
                var components = URLComponents()
                components.scheme = "https"
                components.host = "www.themealdb.com"
                components.path = "/api/json/v1/1/search.php"
                components.queryItems = [ URLQueryItem(name: "f", value: String(letter)) ]

                // If URL construction fails, skip this letter and continue.
                guard let url = components.url else {
                    print("Invalid URL for letter: \(letter)")
                    continue
                }

                // Debug: print the request URL for each letter.
                print("Fetching letter '\(letter)' -> \(url.absoluteString)")

                do {
                    // Perform the network request. Using `data(from:)` returns (Data, URLResponse).
                    let (data, _) = try await URLSession.shared.data(from: url)

                    // Optional debug: print raw JSON returned by the API for this letter.
                    if let raw = String(data: data, encoding: .utf8) {
//                        print("Raw response for '\(letter)':\n\(raw)")
                    }

                    // Decode into your top-level wrapper. Ensure RecipeResponse maps `recipes` to "meals".
                    let decoder = JSONDecoder()
                    let recipeResponse = try decoder.decode(RecipeResponse.self, from: data)

                    // Count is optional; if nil the API returned "meals": null for this letter.
                    let count = recipeResponse.recipes?.count ?? 0
                    print("Decoded \(count) recipes for letter '\(letter)'")

                    // Append decoded recipes (if any) to the gathered array.
                    if let recipes = recipeResponse.recipes {
                        gathered.append(contentsOf: recipes)
                    }
                } catch {
                    // Network/decoding errors are printed but do not abort the entire batch.
                    // This lets other letters in the batch still be fetched.
                    print("Error fetching/decoding for letter '\(letter)':", error)
                }
            }

            // Debug total count gathered in this batch.
            print("Total gathered after batch: \(gathered.count)")

            // Update UI and data source on the main thread:
            //  - Deduplicate using `seenRecipeIds` (avoid duplicates across different letters)
            //  - Append new items to `newRecipes`
            //  - Insert new rows into the table view (animated) or reload if nothing new.
            DispatchQueue.main.async {
                let oldCount = self.newRecipes.count
                for recipe in gathered {
                    // Adjust `recipe.id` if your RecipeData uses a different identifier name.
                    if !self.seenRecipeIds.contains(recipe.id) {
                        self.seenRecipeIds.insert(recipe.id)
                        self.newRecipes.append(recipe)
                    }
                }
                let newCount = self.newRecipes.count
                print("Appended. oldCount=\(oldCount) newCount=\(newCount)")

                if newCount > oldCount {
                    // Build indexPaths for insertion and update the table with animations.
                    var indexPaths: [IndexPath] = []
                    for i in oldCount..<newCount {
                        indexPaths.append(IndexPath(row: i, section: 0))
                    }
                    self.tableView.beginUpdates()
                    self.tableView.insertRows(at: indexPaths, with: .automatic)
                    self.tableView.endUpdates()
                } else {
                    // No new rows appended — reload as a safe fallback.
                    self.tableView.reloadData()
                }

                // Stop the activity indicator.
                self.indicator.stopAnimating()
            }

            // Mark batch as completed and return.
            isFetchingLetterBatch = false
            return
        }

        // -------------------------
        // NON-EMPTY SEARCH MODE
        // Uses search.php?s={name} for multi-character queries and search.php?f={char}
        // for single-character queries (behaves like "starts with" search).
        // -------------------------
        let useFirstLetter = trimmedQuery.count == 1

        var components = URLComponents()
        components.scheme = "https"
        components.host = "www.themealdb.com"
        components.path = "/api/json/v1/1/search.php"
        components.queryItems = [ URLQueryItem(name: useFirstLetter ? "f" : "s", value: trimmedQuery) ]

        // Guard against invalid URL construction.
        guard let requestURL = components.url else {
            print("Invalid URL.")
            DispatchQueue.main.async { self.indicator.stopAnimating() }
            return
        }
        print("Request URL: \(requestURL.absoluteString)")

        // Perform the request and decode the response.
        do {
            let (data, _) = try await URLSession.shared.data(for: URLRequest(url: requestURL))

            // Optional debug: print raw JSON for the query.
            if let raw = String(data: data, encoding: .utf8) {
//                print("Raw response for search '\(trimmedQuery)':\n\(raw)")
            }

            let decoder = JSONDecoder()
            let recipeResponse = try decoder.decode(RecipeResponse.self, from: data)
            print("Recipe counts: \(recipeResponse.recipes?.count ?? 0) ")

            // Replace current results with search results on the main thread.
            DispatchQueue.main.async {
                // Reset local collections/state so the search results are shown cleanly.
                self.newRecipes.removeAll()
                self.seenRecipeIds.removeAll()
                self.currentLetterIndex = 0

                if let recipes = recipeResponse.recipes {
                    for r in recipes {
                        if !self.seenRecipeIds.contains(r.id) {
                            self.seenRecipeIds.insert(r.id)
                            self.newRecipes.append(r)
                        }
                    }
                }

                // Refresh table and stop indicator once search results applied.
                self.tableView.reloadData()
                self.indicator.stopAnimating()
            }
        } catch {
            // Print any networking/decoding errors and ensure the indicator stops.
            print("Search error:", error)
            DispatchQueue.main.async { self.indicator.stopAnimating() }
        }
    }

    // MARK: - UISearchBarDelegate

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        // When editing ends, perform search (empty string triggers letter-batch)
        let searchText = searchBar.text ?? ""

        // Prepare UI and state
        navigationItem.searchController?.dismiss(animated: true)
        indicator.startAnimating()

        // Reset paging state when starting a fresh search
        newRecipes.removeAll()
        seenRecipeIds.removeAll()
        currentLetterIndex = 0
        tableView.reloadData()

        Task {
            URLSession.shared.invalidateAndCancel()
            await requestRecipesNamed(searchText)
        }
    }

    // MARK: - Infinite scroll trigger

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Trigger load-more when reaching near the bottom and the search bar is empty
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let height = scrollView.frame.size.height

        // threshold (100 pts before bottom)
        if offsetY > contentHeight - height - 100 {
            // Only load more when showing default feed (search text empty)
            let searchText = navigationItem.searchController?.searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if searchText.isEmpty && !isFetchingLetterBatch {
                Task {
                    await requestRecipesNamed("") // loads next letter batch
                }
            }
        }
    }
}
