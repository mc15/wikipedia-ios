fileprivate protocol ViewModel {
    var title: String { get }
}

final class InsertMediaImageSizeSettingsTableViewController: UITableViewController {
    private let theme: Theme

    typealias ImageSize = InsertMediaSettings.Advanced.ImageSize

    var selectedImageSize: ImageSize {
        guard
            customSwitch.isOn,
            let widthString = textFieldsGroupedByMeasure[.width]?.text,
            let width = Int(widthString),
            let heightString = textFieldsGroupedByMeasure[.height]?.text,
            let height = Int(heightString)
        else {
            return .default
        }
        return .custom(width: width, height: height)
    }

    private var textFieldsGroupedByMeasure = [Measure: UITextField]()

    private struct ImageSizeViewModel: ViewModel {
        let title: String
        let accessoryView: UIView
    }

    private enum Measure: Hashable {
        case width, height

        var displayTitle: String {
            switch self {
            case .width:
                return WMFLocalizedString("insert-media-image-size-settings-measure-width", value: "Width", comment: "Display title for the measurement of image from side to side")
            case .height:
                return WMFLocalizedString("insert-media-image-size-settings-measure-height", value: "Height", comment: "Display title for the measurement of image from top to base")
            }
        }
    }

    private struct MeasureViewModel: ViewModel {
        let measure: Measure
        let title: String
        let defaultValue: String
        let unitName: String

        init(measure: Measure, defaultValue: String, unitName: String) {
            self.measure = measure
            self.title = measure.displayTitle
            self.defaultValue = defaultValue
            self.unitName = unitName
        }
    }

    private lazy var customSwitch: UISwitch = {
        let customSwitch = UISwitch()
        customSwitch.addTarget(self, action: #selector(reloadData), for: .valueChanged)
        return customSwitch
    }()

    @objc private func reloadData() {
        tableView.reloadData()
    }

    init(theme: Theme) {
        self.theme = theme
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var viewModels: [ViewModel] = {
        let customImageSize = ImageSize.custom(width: ImageSize.defaultWidth, height: ImageSize.defaultHeight)
        let customViewModel = ImageSizeViewModel(title: customImageSize.displayTitle, accessoryView: customSwitch)
        let widthViewModel = MeasureViewModel(measure: .width, defaultValue: "\(ImageSize.defaultWidth)", unitName: ImageSize.unitName)
        let heightViewModel = MeasureViewModel(measure: .height, defaultValue: "\(ImageSize.defaultHeight)", unitName: ImageSize.unitName)
        return [customViewModel, widthViewModel, heightViewModel]
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.identifier)
        tableView.register(InsertMediaCustomImageSizeSettingTableViewCell.wmf_classNib(), forCellReuseIdentifier: InsertMediaCustomImageSizeSettingTableViewCell.identifier)
        tableView.separatorInset = .zero
        tableView.tableFooterView = UIView()
        title = ImageSize.displayTitle
        apply(theme: theme)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModels.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let viewModel = viewModels[indexPath.row]
        switch viewModel {
        case let imageSizeViewModel as ImageSizeViewModel:
            let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.identifier, for: indexPath)
            cell.textLabel?.text = imageSizeViewModel.title
            cell.accessoryView = imageSizeViewModel.accessoryView
            cell.selectionStyle = .none
            apply(theme: theme, to: cell)
            return cell
        case let measureViewModel as MeasureViewModel:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: InsertMediaCustomImageSizeSettingTableViewCell.identifier, for: indexPath) as? InsertMediaCustomImageSizeSettingTableViewCell else {
                return UITableViewCell()
            }
            cell.configure(title: measureViewModel.title, textFieldLabelText: measureViewModel.unitName, textFieldText: measureViewModel.defaultValue, theme: theme)
            cell.selectionStyle = .none
            cell.isUserInteractionEnabled = customSwitch.isOn
            textFieldsGroupedByMeasure[measureViewModel.measure] = cell.textField
            cell.apply(theme: theme)
            return cell
        default:
            return UITableViewCell()
        }
    }

    private func apply(theme: Theme, to cell: UITableViewCell) {
        cell.backgroundColor = theme.colors.paperBackground
        cell.contentView.backgroundColor = theme.colors.paperBackground
        cell.textLabel?.textColor = theme.colors.primaryText
        let selectedBackgroundView = UIView()
        selectedBackgroundView.backgroundColor = theme.colors.midBackground
        cell.selectedBackgroundView = selectedBackgroundView
    }
}

// MARK: - Themeable

extension InsertMediaImageSizeSettingsTableViewController: Themeable {
    func apply(theme: Theme) {
        guard viewIfLoaded != nil else {
            return
        }
        view.backgroundColor = theme.colors.paperBackground
        tableView.separatorColor = theme.colors.border
    }
}