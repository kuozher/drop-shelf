import SwiftUI
import QuickLookThumbnailing

struct FileItem: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    var thumbnail: NSImage?
    
    var fileName: String {
        url.lastPathComponent
    }
}

class FileShelfViewModel: ObservableObject {
    @Published var files: [FileItem] = []
    @Published var selectedIds: Set<UUID> = []
    
    var selectedFiles: [FileItem] {
        files.filter { selectedIds.contains($0.id) }
    }
    
    var selectedCount: Int {
        // Only count selected IDs that actually still exist in the files array
        let validIds = Set(files.map { $0.id })
        return selectedIds.intersection(validIds).count
    }
    
    private var selectionAnchorIndex: Int?
    
    func selectItem(_ id: UUID, cumulative: Bool, shift: Bool) {
        guard let index = files.firstIndex(where: { $0.id == id }) else { return }
        
        if shift, let anchor = selectionAnchorIndex {
            // Select range from anchor to current
            let range = anchor < index ? anchor...index : index...anchor
            let idsInRange = files[range].map { $0.id }
            
            if cumulative {
                selectedIds.formUnion(idsInRange)
            } else {
                selectedIds = Set(idsInRange)
            }
        } else if cumulative {
            // Cmd-click behavior
            if selectedIds.contains(id) {
                selectedIds.remove(id)
            } else {
                selectedIds.insert(id)
            }
            selectionAnchorIndex = index
        } else {
            // Normal click
            selectedIds = [id]
            selectionAnchorIndex = index
        }
    }
    
    func selectAll() {
        selectedIds = Set(files.map { $0.id })
    }
    
    func deselectAll() {
        selectedIds.removeAll()
        selectionAnchorIndex = nil
    }
    
    func addFile(url: URL) {
        // Prevent duplicates
        guard !files.contains(where: { $0.url == url }) else { return }
        
        let newItem = FileItem(url: url)
        files.append(newItem)
        generateThumbnail(for: url)
    }
    
    func removeFile(withURL url: URL) {
        if let item = files.first(where: { $0.url == url }) {
            selectedIds.remove(item.id)
            files.removeAll(where: { $0.url == url })
        }
    }
    
    func clearAll() {
        files.removeAll()
        selectedIds.removeAll()
    }
    
    private func generateThumbnail(for url: URL) {
        let size = CGSize(width: 80, height: 80)
        let scale = NSScreen.main?.backingScaleFactor ?? 2.0
        let request = QLThumbnailGenerator.Request(fileAt: url, size: size, scale: scale, representationTypes: .thumbnail)
        
        QLThumbnailGenerator.shared.generateRepresentations(for: request) { (representation, type, error) in
            DispatchQueue.main.async {
                if let thumb = representation?.nsImage,
                   let index = self.files.firstIndex(where: { $0.url == url }) {
                    self.files[index].thumbnail = thumb
                }
            }
        }
    }
}
