class HelmAT21612 < Formula
  desc "Kubernetes package manager"
  homepage "https://helm.sh/"
  url "https://github.com/helm/helm.git",
      tag:      "v2.16.12",
      revision: "47f0b88409e71fd9ca272abc7cd762a56a1c613e"
  license "Apache-2.0"

  # NOTE: Remove this livecheck block after deprecation takes effect, so we
  # don't unnecessarily check for updates.
  livecheck do
    url :stable
    regex(/^v?(2(?:\.\d+)+)$/i)
  end

  keg_only :versioned_formula

  # See: https://helm.sh/blog/helm-v2-deprecation-timeline/
  deprecate! date: "2020-11-13", because: :deprecated_upstream

  depends_on "glide" => :build
  depends_on "go" => :build

  def install
    ENV["GOPATH"] = buildpath
    ENV["GLIDE_HOME"] = HOMEBREW_CACHE/"glide_home/#{name}"
    ENV.prepend_create_path "PATH", buildpath/"bin"
    ENV["TARGETS"] = "darwin/amd64"
    dir = buildpath/"src/k8s.io/helm"
    dir.install buildpath.children - [buildpath/".brew_home"]

    cd dir do
      # system "go", "mod", "init"
      # system "go", "mod", "vendor"
      # system "go" "build" "-o" "bin/protoc-gen-go" "./vendor/github.com/golang/protobuf/protoc-gen-go"
      system "glide", "install", "--strip-vendor"
      # system "make", "bootstrap"
      system "make", "build"

      bin.install "bin/helm"
      bin.install "bin/tiller"
      man1.install Dir["docs/man/man1/*"]

      output = Utils.safe_popen_read({ "SHELL" => "bash" }, bin/"helm", "completion", "bash")
      (bash_completion/"helm").write output

      output = Utils.safe_popen_read({ "SHELL" => "zsh" }, bin/"helm", "completion", "zsh")
      (zsh_completion/"_helm").write output

      prefix.install_metafiles
    end
  end

  test do
    system "#{bin}/helm", "create", "foo"
    assert File.directory? "#{testpath}/foo/charts"

    version_output = shell_output("#{bin}/helm version --client 2>&1")
    assert_match "GitTreeState:\"clean\"", version_output
    if build.stable?
      assert_match stable.instance_variable_get(:@resource).instance_variable_get(:@specs)[:revision], version_output
    end
  end
end
