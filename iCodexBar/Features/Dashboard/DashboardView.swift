import SwiftUI

struct DashboardView: View {
    @State private var viewModel = DashboardViewModel()

    private let columns = [
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                if !viewModel.hasAnyConfiguredKey {
                    emptyState
                } else {
                    configuredState
                }
            }
            .navigationTitle("iCodexBar")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        Button {
                            Task { await viewModel.refresh() }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                if !AppRuntime.isRunningTests {
                    await viewModel.refresh()
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "gauge.with.dots.needle.bottom.50percent")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text("Welcome to iCodexBar")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Add an API key in Settings to start tracking your AI usage.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 400)
    }

    // MARK: - Configured State

    private var configuredState: some View {
        LazyVStack(spacing: 12) {
            // Last updated
            if let lastFetched = viewModel.lastFetchedAt {
                HStack {
                    Text("Updated \(UsageFormatter.formatRelativeDate(lastFetched))")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
                .padding(.horizontal, 4)
            }

            // Provider cards
            ForEach(Provider.allCases) { provider in
                UsageCardView(
                    provider: provider,
                    snapshot: viewModel.snapshot(for: provider),
                    error: viewModel.error(for: provider),
                    isLoading: viewModel.isLoading
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

#Preview {
    DashboardView()
}
