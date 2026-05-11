import SwiftUI
import MapKit

struct MapTabView: View {
    @State private var searchText = ""
    @State private var cityText = ""
    @State private var results: [AMapPOI] = []
    @State private var isSearching = false
    @State private var errorMsg: String? = nil
    @State private var selectedPOI: AMapPOI? = nil

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            if isSearching {
                ProgressView()
                    .padding(40)
                Spacer()
            } else if results.isEmpty && !searchText.isEmpty {
                emptyState
            } else if results.isEmpty {
                hintState
            } else {
                resultList
            }
        }
        .background(AppColors.background)
        .navigationTitle("地图")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $selectedPOI) { poi in
            POIDetailSheet(poi: poi)
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("搜索地点、车站、机场、景点…", text: $searchText)
                    .submitLabel(.search)
                    .onSubmit { performSearch() }
                if !searchText.isEmpty {
                    Button { searchText = ""; results = []; errorMsg = nil } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(10)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))

            HStack(spacing: 8) {
                Image(systemName: "location")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("城市（可选，留空搜全国）", text: $cityText)
                    .font(.caption)
                Spacer()
                Button("搜索") { performSearch() }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.primary)
                    .disabled(searchText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppColors.background)
    }

    // MARK: - States

    private var hintState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "map.fill")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(AppColors.primary.opacity(0.4))
            Text("搜索地点")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("可搜索酒店、车站、机场、景点\n支持高德地图导航")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
            Spacer()
        }
        .padding()
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "location.slash")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("没有找到相关地点")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("试试调整关键词或城市范围")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if let err = errorMsg {
                Text(err).font(.caption).foregroundStyle(.red)
            }
            Spacer()
            Spacer()
        }
        .padding()
    }

    // MARK: - Results

    private var resultList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                if let err = errorMsg {
                    Text(err).font(.caption).foregroundStyle(.red).padding(.horizontal)
                }
                ForEach(results) { poi in
                    POIRow(poi: poi)
                        .onTapGesture { selectedPOI = poi }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Search

    private func performSearch() {
        let kw = searchText.trimmingCharacters(in: .whitespaces)
        guard !kw.isEmpty else { return }
        isSearching = true
        errorMsg = nil
        Task {
            do {
                results = try await AMapService.shared.searchPOI(keyword: kw, city: cityText)
                if results.isEmpty { errorMsg = nil }
            } catch {
                errorMsg = "搜索失败：\(error.localizedDescription)"
            }
            isSearching = false
        }
    }
}

// MARK: - POI Row

private struct POIRow: View {
    let poi: AMapPOI

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: poiIcon(poi.typecode))
                .font(.system(size: 17))
                .foregroundStyle(AppColors.primary)
                .frame(width: 36, height: 36)
                .background(AppColors.primary.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(poi.name)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                Text(poi.address.isEmpty ? "暂无地址" : poi.address)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .shadow(color: .black.opacity(0.04), radius: 3, y: 1)
    }

    private func poiIcon(_ typecode: String) -> String {
        switch typecode.prefix(2) {
        case "11": return "airplane"
        case "15": return "tram.fill"
        case "17": return "bus"
        case "16": return "car.fill"
        case "07": return "bed.double.fill"
        case "05": return "fork.knife"
        case "08": return "cart.fill"
        case "06": return "storefront"
        default:   return "mappin.circle.fill"
        }
    }
}

// MARK: - POI Detail Sheet

struct POIDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let poi: AMapPOI

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Mini map preview
                if let coord = poi.coordinate {
                    Map(coordinateRegion: .constant(
                        MKCoordinateRegion(
                            center: coord,
                            span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
                        )
                    ), annotationItems: [poi]) { p in
                        MapMarker(coordinate: p.coordinate ?? coord, tint: AppColors.primary)
                    }
                    .frame(height: 200)
                }

                // Info card
                VStack(alignment: .leading, spacing: 12) {
                    Text(poi.name)
                        .font(.title3.weight(.bold))
                    if !poi.address.isEmpty {
                        Label(poi.address, systemImage: "mappin")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if let coord = poi.coordinate {
                        Label(String(format: "%.5f, %.5f", coord.latitude, coord.longitude),
                              systemImage: "location.circle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Divider()

                    HStack(spacing: 12) {
                        actionButton(
                            title: "在高德中查看",
                            icon: "map.fill",
                            color: AppColors.primary
                        ) {
                            if let coord = poi.coordinate {
                                AMapService.shared.openInMap(coordinate: coord, name: poi.name)
                            }
                        }

                        actionButton(
                            title: "导航前往",
                            icon: "arrow.triangle.turn.up.right.circle.fill",
                            color: .green
                        ) {
                            if let coord = poi.coordinate {
                                AMapService.shared.openNavigation(to: coord, name: poi.name)
                            }
                        }
                    }
                }
                .padding(20)
                .background(.white)

                Spacer()
            }
            .background(AppColors.background)
            .navigationTitle("地点详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }

    private func actionButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
                    .font(.subheadline.weight(.medium))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
        }
    }
}
