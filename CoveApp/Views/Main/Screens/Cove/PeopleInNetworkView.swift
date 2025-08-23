
//
//  PeopleInNetworkView.swift
//  Cove
//

import SwiftUI
import Kingfisher

struct PeopleInNetworkView: View {
	@EnvironmentObject private var appController: AppController
	@ObservedObject private var viewModel: MutualsViewModel = AppController.shared.mutualsViewModel
	var disableNavigation: Bool = false

	var body: some View {
		ZStack {
			Colors.background.ignoresSafeArea()

			VStack(spacing: 0) {
				ScrollView(showsIndicators: false) {
					VStack(spacing: 30) {
						contentSection
					}
					.padding(.top, 20)
				}
				.refreshable {
					await withCheckedContinuation { continuation in
						viewModel.refresh { continuation.resume() }
					}
				}
			}
		}
		.navigationBarBackButtonHidden()
		.alert("Error", isPresented: Binding(get: { viewModel.errorMessage != nil }, set: { if !$0 { viewModel.errorMessage = nil } })) {
			Button("OK") { viewModel.errorMessage = nil }
		} message: {
			Text(viewModel.errorMessage ?? "")
		}
		.onAppear { viewModel.loadNextPageIfStale() }
	}

	// MARK: - Sections
	@ViewBuilder
	private var contentSection: some View {
		if (viewModel.isLoading || viewModel.isRefreshing) && viewModel.mutuals.isEmpty {
			loadingPlaceholder
		} else if let error = viewModel.errorMessage, viewModel.mutuals.isEmpty {
			errorPlaceholder(error)
		} else if viewModel.mutuals.isEmpty {
			emptyPlaceholder
		} else {
			listSection
		}
	}

	private var loadingPlaceholder: some View {
		VStack(spacing: 16) {
			ProgressView().tint(Colors.primaryDark)
			Text("loading people...")
				.font(.LibreBodoni(size: 16))
				.foregroundColor(Colors.primaryDark)
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.padding(.top, 100)
	}

	private func errorPlaceholder(_ error: String) -> some View {
		VStack(spacing: 16) {
			Image(systemName: "exclamationmark.circle")
				.font(.system(size: 40))
				.foregroundColor(.gray)
			Text(error)
				.font(.LibreBodoni(size: 16))
				.foregroundColor(.gray)
				.multilineTextAlignment(.center)
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.padding(.top, 100)
	}

	private var emptyPlaceholder: some View {
		VStack(spacing: 16) {
			Image(systemName: "person.2.slash")
				.font(.system(size: 40))
				.foregroundColor(Colors.primaryDark)
			Text("no people in your network yet")
				.font(.LibreBodoni(size: 16))
				.foregroundColor(Colors.primaryDark)
				.multilineTextAlignment(.center)
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.padding(.top, 100)
	}

	private var listSection: some View {
		VStack(spacing: 30) {
			ForEach(viewModel.mutuals) { person in
				NavigationLink(destination: FriendProfileView(userId: person.id, initialPhotoUrl: person.profilePhotoUrl)) {
					HStack(spacing: 16) {
						profileImage(url: person.profilePhotoUrl)
						VStack(alignment: .leading, spacing: 4) {
							Text(person.name)
								.font(.LibreBodoni(size: 16))
								.foregroundStyle(Color.black)
							Text("\(person.sharedCoveCount) shared cove\(person.sharedCoveCount == 1 ? "" : "s")")
								.font(.LibreBodoni(size: 12))
								.foregroundStyle(Color.black.opacity(0.6))
						}
						Spacer()
						if viewModel.pendingRequests.contains(person.id) {
							ActionButton.pending()
						} else {
							ActionButton.request { viewModel.sendFriendRequest(to: person.id) }
						}
					}
					.padding(.horizontal, 20)
				}
				.disabled(disableNavigation)
				.buttonStyle(.plain)
				.onAppear {
					if person.id == viewModel.mutuals.last?.id { viewModel.loadNextPage() }
				}
			}
			if viewModel.isLoading && !viewModel.mutuals.isEmpty {
				HStack { Spacer(); ProgressView().tint(Colors.primaryDark); Spacer() }
					.padding(.vertical, 16)
			}
		}
	}

	@ViewBuilder
	private func profileImage(url: URL?) -> some View {
		if let url = url {
			KFImage(url)
				.resizable()
				.placeholder { Circle().fill(Color.gray.opacity(0.3)).overlay(ProgressView().tint(.gray)) }
				.scaledToFill()
				.frame(width: 60, height: 60)
				.clipShape(Circle())
		} else {
			Image("default_user_pfp")
				.resizable()
				.scaledToFill()
				.frame(width: 60, height: 60)
				.clipShape(Circle())
		}
	}
}

// MARK: — Preview

struct PeopleInNetworkView_Previews: PreviewProvider {
	static var previews: some View {
		PeopleInNetworkView()
			.environmentObject(AppController.shared)
			.previewDevice("iPhone 13")
	}
}
